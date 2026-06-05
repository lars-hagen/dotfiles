# Bun CLI and Backend Patterns

Reference for Bun as a replacement for Python CLIs, subprocess wrappers, REST APIs, and test workflows.

## 1. Standalone CLI Executables

### Basic `bun build --compile` usage

`bun build --compile` bundles your code and the Bun runtime into a single native executable. This is the closest Bun equivalent to shipping a Python app with PyInstaller or similar tools.

```bash
bun build --compile ./cli.ts --outfile mycli
bun build --compile --target=bun-windows-x64 ./cli.ts --outfile mycli
bun build --compile --minify --sourcemap --bytecode ./cli.ts --outfile mycli
```

Notes:

- No separate Bun runtime is required on the destination machine.
- Windows adds the `.exe` extension automatically.
- `--compile` works well for command-line tools, local agents, and small API daemons.

### Cross-compilation targets

Use `--target=` to build for a different platform.

| Target                 | OS      | CPU   | libc / ABI     |
| ---------------------- | ------- | ----- | -------------- |
| `bun-linux-x64`        | Linux   | x64   | glibc          |
| `bun-linux-arm64`      | Linux   | arm64 | glibc          |
| `bun-windows-x64`      | Windows | x64   | native Windows |
| `bun-windows-arm64`    | Windows | arm64 | native Windows |
| `bun-darwin-x64`       | macOS   | x64   | native Darwin  |
| `bun-darwin-arm64`     | macOS   | arm64 | native Darwin  |
| `bun-linux-x64-musl`   | Linux   | x64   | musl           |
| `bun-linux-arm64-musl` | Linux   | arm64 | musl           |

Related x64 variants exist for CPU compatibility and performance tuning, such as `bun-linux-x64-baseline` for older CPUs and `bun-linux-x64-modern` for newer CPUs.

### Production flags

Common release flags:

- `--minify` reduces bundle size.
- `--sourcemap` emits source maps for debugging crash reports.
- `--bytecode` precompiles JavaScriptCore bytecode to reduce startup parsing cost.

Example:

```bash
bun build --compile --minify --sourcemap --bytecode ./cli.ts --outfile mycli
```

### Windows-specific executable options

Compiled Windows executables support extra metadata and packaging flags:

- `--windows-icon=./app.ico`
- `--windows-hide-console`
- `--windows-title="My CLI"`
- `--windows-publisher="Example Corp"`
- `--windows-version=1.2.3`
- `--windows-description="Command-line utility"`
- `--windows-copyright="Copyright 2026 Example Corp"`

Use these when distributing a GUI helper, tray app, or polished internal tool on Windows.

### Build-time constants with `--define`

Like esbuild, Bun can inline constants at build time:

```bash
bun build --compile ./cli.ts --outfile mycli --define:BUILD_ENV='"production"' --define:FEATURE_X=true
```

Use this for version strings, feature flags, endpoint selection, and environment-specific behavior.

### Embedding files

Embed assets directly into the executable with import attributes:

```ts
import templatePath from "./templates/report.md" with { type: "file" };

console.log(templatePath);
console.log(Bun.embeddedFiles);
```

This is useful for shipping templates, certificates, SQL files, migrations, or static config without extra deployment steps.

### Embedding SQLite

SQLite databases can also be embedded:

```ts
import db from "./seed.db" with { type: "sqlite", embed: "true" };
```

Useful for read-only reference data, seed datasets, lookup tables, and offline-first tools.

### Workers in compiled executables

Compiled Bun executables can spawn `Worker` threads. That makes it practical to keep CPU-heavy parsing, background jobs, or isolated workloads off the main thread even after compilation.

### Config autoloading defaults

For compiled executables, Bun enables some config autoloading by default:

- `.env` loading is enabled.
- `bunfig.toml` loading is enabled.
- `tsconfig.json` loading is disabled.
- `package.json` loading is disabled.

To disable dotenv loading in compiled binaries, use:

```bash
bun build --compile --no-compile-autoload-dotenv ./cli.ts --outfile mycli
```

### Make the executable behave like `bun`

Set `BUN_BE_BUN=1` to make a compiled executable behave like the Bun CLI itself. This is mainly useful for advanced tooling and wrapper scenarios.

### Runtime flags via `BUN_OPTIONS`

Set `BUN_OPTIONS` to pass Bun runtime flags to compiled executables at launch time. This is helpful for debugging, tuning, or enabling runtime behaviors without rebuilding.

### Standalone startup cost and the shim pattern

`bun build --compile` produces binaries that include the full Bun runtime. Empty compiled binaries start in around 50 ms warm, but real CLIs with heavy deps (`@azure/identity`, `@azure/msal-node`, `ldapts`, `@clack/prompts`, and similar) land around 700 to 900 ms warm, even with `--minify --bytecode`. `await import()` inside command handlers does not help in compiled mode because Bun unpacks the full bundle into memory before `main` runs; lazy imports only defer execution, not disk reads.

This matters for local developer tools invoked dozens of times per session (help text, tab completion, shell prompts). 800 ms per call is painful.

For machines that already have `bun` on PATH, install a shim that invokes the source entry via `bun` instead of the standalone binary. This cuts warm startup from around 800 ms to around 110 ms (about 7x):

```js
// scripts/rebuild-standalone.mjs
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { mkdirSync, writeFileSync, chmodSync } from "node:fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = dirname(__dirname);
const distDir = resolve(repoRoot, "dist");
const entry = resolve(repoRoot, "cli/bin/mycli.js");
const installDir = process.env.BIN_DIR ?? `${process.env.HOME}/.bun/bin`;
const distOutFile = `${distDir}/mycli`;

mkdirSync(distDir, { recursive: true });

// 1. Build standalone for distribution (dist/, NOT on PATH)
const build = spawnSync(
  "bun",
  ["build", "--compile", "--minify", "--bytecode", entry, "--outfile", distOutFile],
  { cwd: repoRoot, stdio: "inherit" },
);
if (build.status !== 0) process.exit(build.status ?? 1);

// 2. Install fast shim on PATH (NOT the standalone binary)
mkdirSync(installDir, { recursive: true });
const shim = `${installDir}/mycli`;
writeFileSync(shim, `#!/usr/bin/env sh\nexec bun "${entry}" "$@"\n`, "utf8");
chmodSync(shim, 0o755);
```

Two install targets:

1. **`dist/<name>`** - standalone binary, for handoff to machines that do not have Bun. Kept out of PATH so it does not shadow the fast shim.
2. **`$BIN_DIR/<name>`** - the `sh` shim on PATH, used daily.

For CLIs that must run on Bun-less machines, ship the standalone binary. For local dev, ship the shim. You can do both from the same build script, as shown above.

### Operational scripts colocated with the CLI

For repos that build a CLI plus operate adjacent infrastructure (Terraform, K8s, secret rotation), keep operational helpers as `scripts/*.mjs` and expose them via `package.json` scripts. Each helper is a thin Bun script that shells out to the real tools (`terraform`, `kubectl`, `gcloud`, the CLI itself) and inherits stdio so logs stream live.

```json
{
  "scripts": {
    "build": "bun scripts/rebuild-standalone.mjs",
    "rotate-graph-app": "bun scripts/rotate-graph-app.mjs",
    "test": "bun test"
  }
}
```

Pattern for a rotation script:

```js
// scripts/rotate-graph-app.mjs
import { spawnSync } from "node:child_process";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const infraDir = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "infra",
);

function run(cmd, args) {
  const res = spawnSync(cmd, args, {
    cwd: infraDir,
    stdio: "inherit",
    shell: false,
  });
  if (res.error) {
    console.error(res.error.message);
    process.exit(1);
  }
  return res.status ?? 1;
}
function capture(cmd, args) {
  const res = spawnSync(cmd, args, {
    cwd: infraDir,
    stdio: ["ignore", "pipe", "inherit"],
    shell: false,
  });
  if (res.status !== 0) process.exit(res.status ?? 1);
  return res.stdout.toString().trim();
}

run("terraform", ["taint", "tls_private_key.app"]); // tolerate first-run failure
if (run("terraform", ["apply", "-auto-approve"]) !== 0) process.exit(1);

const tenant = capture("terraform", ["output", "-raw", "tenant_id"]);
const pfx = capture("terraform", ["output", "-raw", "pfx_path"]);
run("mycli", ["auth", "configure", "--tenant", tenant, "--cert-path", pfx]);
```

Why this shape:

- `shell: false` keeps args literal, no quoting bugs.
- `stdio: 'inherit'` for `run` so users see Terraform's output live; `'pipe'` only when capturing `terraform output -raw`.
- Single-purpose scripts. One script per operation; never a god-script with subcommands. Keeps each one auditable and lets `package.json` be the operation index.
- The script is versioned, reviewable, and runnable by anyone with the toolchain installed. The procedure cannot drift from the `terraform output` names because they live in the same repo.

Avoid `Bun.$` here: it adds shell quoting semantics where you want raw exec, and the failure mode for a missing binary is less obvious than `spawnSync`.

## 2. package.json bin field

For package-style CLIs, register entry points in `package.json`:

```json
{
  "name": "my-tool",
  "bin": {
    "my-tool": "./cli.ts"
  }
}
```

On Unix-style systems, scripts can also use a shebang:

```ts
#!/usr/bin/env bun
console.log("hello");
```

This is the Bun/Node ecosystem equivalent of Python's `[project.scripts]` entry points. The `bin` field wires commands into package-manager installs; `bun build --compile` produces a standalone native executable instead.

## 3. API Server Patterns

### `Bun.serve()` for pure REST APIs

You do not need HTML imports or frontend assets. Bun works well as a plain HTTP API server:

```ts
const server = Bun.serve({
  port: 8000,
  routes: {
    "/api/health": () => Response.json({ ok: true }),
    "/api/items/:id": (req) => Response.json({ id: req.params.id }),
  },
  fetch() {
    return new Response("Not found", { status: 404 });
  },
});
```

This is a good migration path for Python FastAPI or Flask services when you want a lightweight runtime and TypeScript everywhere.

### Route patterns

Common Bun route styles:

- Static routes: `"/api/health"`
- Dynamic params: `"/api/items/:id"`
- Wildcards: `"/files/*"`

### HTTP methods

Route objects support per-method handlers:

```ts
Bun.serve({
  routes: {
    "/api/items": {
      async GET() {
        return Response.json([{ id: 1 }]);
      },
      async POST(req) {
        return Response.json(await req.json(), { status: 201 });
      },
    },
    "/api/items/:id": {
      async PUT(req) {
        return Response.json({ id: req.params.id, body: await req.json() });
      },
      async DELETE(req) {
        return Response.json({ deleted: req.params.id });
      },
    },
  },
});
```

### Graceful shutdown

Keep a reference to the server and stop it on process signals:

```ts
const server = Bun.serve({
  port: 8000,
  fetch: () => Response.json({ ok: true }),
});

process.on("SIGTERM", () => {
  server.stop();
});

process.on("SIGINT", () => {
  server.stop();
});
```

This mirrors production shutdown handling in Python services and containers.

### Static file serving

Bun can also serve static assets alongside an API via `static` routes when needed. That is useful for internal dashboards, docs, exported reports, or API-plus-assets deployments.

### TLS support

`Bun.serve()` supports TLS configuration directly, so small HTTPS services can run without an extra Node package.

### Experimental HTTP/3 with `Bun.serve()`

v1.3.14 adds highly experimental HTTP/3 over QUIC support. Enable it only for experiments unless the user explicitly accepts the risk.

```ts
Bun.serve({
  port: 443,
  tls: { cert, key },
  http3: true,
  fetch() {
    return new Response("ok");
  },
});
```

When `http3: true` is set with TLS, Bun binds TCP for HTTP/1.1+2 and UDP for HTTP/3 on the same port. Current limitations: no WebSocket over HTTP/3, no 0-RTT, no trailers, and no HTTP/1.1-style `Expect: 100-continue`.

### Streaming responses

Bun supports streaming HTTP responses with standard Web APIs. This is useful for logs, SSE-style output, proxies, large downloads, or incremental API responses.

## 4. Shell API (Bun.$)

### Template literal syntax

Bun's shell API replaces many subprocess wrappers:

```ts
import { $ } from "bun";

await $`git status`;
```

This is often a direct replacement for Python `subprocess.run()` in CLI automation.

### Output capture

Capture command results in several formats:

```ts
const text = await $`echo hello`.text();
const json = await $`cat package.json`.json();
const lines = await $`git branch --list`.lines();
const blob = await $`cat ./image.png`.blob();
```

### Error handling

Useful helpers:

- `.nothrow()` prevents exceptions on non-zero exit.
- `.quiet()` suppresses terminal output.
- `ShellError.exitCode` exposes the exit code on failures.

```ts
const result = await $`cmd`.nothrow().quiet();
if (result.exitCode !== 0) {
  console.error("command failed");
}
```

### Redirection and pipes

Shell operators are supported:

- stdin redirection: `<`
- stdout redirection: `>`
- stderr redirection: `2>`
- combined redirection: `&>`
- pipes: `|`

This makes Bun suitable for file-oriented automation and data-processing CLIs.

### JavaScript interop

Commands can interoperate with Web and Bun objects such as `Response`, `Buffer`, and `Bun.file()` for stdin or stdout plumbing. That keeps CLI code inside TypeScript instead of shell-script glue.

### Environment variables and working directory

Per-command overrides are available:

```ts
await $`bun test`.cwd("./packages/api").env({ NODE_ENV: "test" });
```

### Built-in cross-platform commands

Bun includes portable built-ins for common shell tasks, including:

- `ls`
- `rm`
- `echo`
- `pwd`
- `cat`
- `touch`
- `mkdir`
- `which`
- `mv`
- `cd`

These help reduce platform-specific shell differences in scripts.

### Security

Interpolated values are escaped automatically, which helps prevent shell injection. The main place to be careful is when you deliberately hand off a string to `bash -c`, `sh -c`, or similar shell parsing layers.

## 5. Test Runner

See `references/test-runner.md` for the full reference: every flag, modifier chaining, `--changed` / `--parallel` / `--shard`, coverage thresholds, type-level matchers, CI strictness. Quick reminder:

```ts
import {
  test,
  expect,
  describe,
  mock,
  beforeAll,
  afterAll,
  beforeEach,
  afterEach,
} from "bun:test";

test("adds", () => {
  expect(2 + 2).toBe(4);
});
```

```bash
bun test                          # run
bun test --watch                  # watch mode
bun test --coverage               # coverage
bun test --changed                # only files affected by git changes
bun test --reporter=junit --reporter-outfile=results.xml
```

## 6. Native fetch

`fetch()` is built into Bun. No npm package is required.

This is the natural replacement for Python `requests` in many scripts and services:

```ts
const response = await fetch("https://api.example.com/items", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ name: "demo" }),
});

const data = await response.json();
```

Useful response readers include:

- `response.json()`
- `response.text()`
- `response.arrayBuffer()`
- `response.blob()`

Bun's native `fetch()` also works cleanly with streaming request and response bodies.

v1.3.14 adds experimental HTTP/2 and HTTP/3 clients:

```ts
await fetch("https://example.com", { protocol: "http2" });
await fetch("https://example.com", { protocol: "http3" });
```

HTTP/2 can be enabled globally with `--experimental-http2-fetch` or `BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP2_CLIENT=1`. HTTP/3 Alt-Svc upgrades can be enabled with `--experimental-http3-fetch` or `BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP3_CLIENT=1`. Keep this as experimental guidance, not a production default.

## 7. Environment and .env

See `references/builtin-apis.md` "Environment" for the canonical precedence table and deployment hardening notes. Quick reminders:

```ts
const port = Number(process.env.PORT ?? 8000);
```

Disable env autoloading for a project in `bunfig.toml`:

```toml
env = false
```

For compiled executables, dotenv loading is enabled by default and can be disabled with `--no-compile-autoload-dotenv`.

## 8. Supervised process cleanup

For Bun scripts or daemons launched by Electron, CI runners, shims, local agents, or other supervisors, use `--no-orphans` on Linux/macOS so Bun exits when the parent process dies and recursively kills descendants it spawned:

```bash
bun --no-orphans run worker
```

```toml
[run]
noOrphans = true
```

This is a no-op on Windows.

## 9. Interactive terminal helpers

`Bun.Terminal` now works on Windows via ConPTY in addition to POSIX PTYs. Use it with `Bun.spawn({ terminal })` for full-screen terminal tools, shells, and interactive subprocesses. Windows caveats: termios flags are no-ops, output escape sequences may be re-encoded, and input without a child process is buffered.

For simple terminal size and raw-mode needs, `process.stdout.columns`, `process.stdout.rows`, and `process.stdin.setRawMode(true)` are usually simpler.

## 10. POSIX process replacement

`process.execve(execPath, args, env)` is available on POSIX and matches Node.js v24. It replaces the current process image and never returns on success. Use only for wrapper/launcher CLIs that need true `execve(2)` semantics; it throws on Windows and from worker threads.
