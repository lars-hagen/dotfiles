# Bun Runtime Flags and Top-Level Commands

Flags and commands that apply to the `bun` binary itself, not to a specific subcommand. Updated for v1.3.14.

## Execution Shortcuts

### `bun -e` / `bun -p`

Evaluate a string as a script. `-p` additionally prints the result.

```bash
bun -e 'console.log(Bun.version)'
bun -p 'Bun.randomUUIDv7()'
bun -p 'await fetch("https://api.example.com").then(r => r.json())'
```

Use for one-liners, CI checks, or probing runtime values without a file.

### `bun exec`

Run a shell script with Bun's `$` shell directly from the CLI.

```bash
bun exec 'ls -la | grep ts'
```

Equivalent to running the string through `Bun.$` from a TypeScript file. Portable across platforms thanks to Bun's shell built-ins.

### `bun repl`

Interactive REPL with syntax highlighting, history, and tab completion.

```bash
bun repl
```

Top-level `await` is supported. `Bun.*` globals are available.

### `--if-present`

Exit with code 0 if the entrypoint does not exist. Useful for optional scripts in CI.

```bash
bun --if-present scripts/postbuild.ts
```

## Auto-Install

Bun can install missing imports on the fly when running scripts without a full project setup.

**Do not use `-i` / `--install=fallback` / `--install=auto` in CI, Dockerfiles, or production entrypoints.** These flags fetch packages from npm at runtime. An attacker who can influence an import specifier (environment variable, argument, generated code) causes arbitrary-package installation on the running host. For production: `bun install --frozen-lockfile` ahead of time, then run the app with `--no-install`.

| Flag                 | Behavior                                             |
| -------------------- | ---------------------------------------------------- |
| `-i`                 | Shorthand for `--install=fallback`.                  |
| `--install=auto`     | Default. Auto-install when no `node_modules` exists. |
| `--install=fallback` | Install only missing packages.                       |
| `--install=force`    | Always check npm, always reinstall.                  |
| `--no-install`       | Disable auto-install entirely. Use in production.    |

```bash
bun -i script.ts                # local dev only: install any missing imports, then run
bun --no-install script.ts      # production: fail if anything is missing
```

See also the `--analyze` flag on `bun install` in `package-manager.md`, which has the same supply-chain trade-off.

## Memory and Performance

### `--smol`

Run with reduced memory overhead. More frequent GC cycles. Recommended for memory-constrained environments such as small cloud VMs, Raspberry Pi, or sidecar containers.

```bash
bun --smol server.ts
```

### `--expose-gc`

Exposes `gc()` on the global object. Does not affect `Bun.gc()` which is always available. Use only when intentionally triggering GC in tests or benchmarks.

### Preconnect flags

Warm up external connections while code is still loading so the first real request does not pay the handshake cost.

| Flag                       | What it preconnects to                                       |
| -------------------------- | ------------------------------------------------------------ |
| `--fetch-preconnect=<URL>` | HTTP(S) host. TCP + TLS + HTTP/2 handshake. Can be repeated. |
| `--redis-preconnect`       | `$REDIS_URL`.                                                |
| `--sql-preconnect`         | `$DATABASE_URL` / PostgreSQL.                                |

```bash
bun --fetch-preconnect=https://api.example.com --sql-preconnect server.ts
```

Especially valuable for serverless cold starts.

### Experimental HTTP/2 and HTTP/3 fetch

Opt into experimental HTTP/2 or HTTP/3 client support globally, or prefer per-request `protocol` when experimenting locally.

```bash
bun --experimental-http2-fetch app.ts
bun --experimental-http3-fetch app.ts
BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP2_CLIENT=1 bun app.ts
BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP3_CLIENT=1 bun app.ts
```

```ts
await fetch("https://example.com", { protocol: "http2" });
await fetch("https://example.com", { protocol: "http3" });
```

`--experimental-http3-fetch` enables transparent Alt-Svc HTTP/3 upgrades for subsequent requests to origins that advertise `Alt-Svc: h3`. These features are experimental; do not recommend as production defaults yet.

## Profiling (Built-in)

Bun ships CPU and heap profilers with optional Markdown output designed for LLM analysis. No external tooling required.

### CPU profiling

```bash
bun --cpu-prof cli.ts
bun --cpu-prof --cpu-prof-name=run1 --cpu-prof-dir=./profiles cli.ts
bun --cpu-prof --cpu-prof-interval=500 cli.ts   # 500-microsecond sampling (0.5 ms)
bun --cpu-prof-md cli.ts                        # grep-friendly markdown output
```

The `.cpuprofile` output opens in Chrome DevTools > Performance > Load Profile. The `--cpu-prof-md` variant emits a Markdown report meant for piping into an AI assistant when diagnosing hot paths.

### Heap snapshots

```bash
bun --heap-prof cli.ts                 # .heapsnapshot file
bun --heap-prof-md cli.ts              # markdown report
bun --heap-prof --heap-prof-dir=./heap cli.ts
```

`.heapsnapshot` files open in Chrome DevTools > Memory. Programmatic heap capture is also available via `Bun.generateHeapSnapshot()`.

## Debugger

### `--inspect`

Opens Bun's debugger on a random port. `--inspect-wait` blocks until a client connects. `--inspect-brk` pauses on the first line of user code.

```bash
bun --inspect server.ts
bun --inspect-wait=6499 server.ts
bun --inspect-brk cli.ts
```

Connect with the VSCode extension, Chrome DevTools, or Safari Web Inspector. Bun uses the WebKit Inspector Protocol.

## Process and TLS

| Flag                                                 | Purpose                                                                                     |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `--title=<name>`                                     | Set process title (appears in `ps`, Activity Monitor, Task Manager).                        |
| `--preload=<file>` / `-r` / `--require` / `--import` | Preload a module before user code. Useful for instrumentation, polyfills, telemetry.        |
| `--conditions=<val>`                                 | Add custom resolution conditions. Stack with `--conditions=react-server --conditions=node`. |
| `--use-system-ca`                                    | Trust the OS certificate store. See security note below.                                    |
| `--use-openssl-ca`                                   | Trust OpenSSL's bundled CA list.                                                            |
| `--use-bundled-ca`                                   | Trust Bun's bundled CA list. Default.                                                       |
| `--dns-result-order=<val>`                           | `verbatim` (default), `ipv4first`, `ipv6first`. Fixes IPv6-hostile networks.                |
| `--max-http-header-size=<bytes>`                     | Default 16 KiB. Increase for services with oversized auth headers.                          |
| `--zero-fill-buffers`                                | Force `Buffer.allocUnsafe()` to zero memory. Defense-in-depth for security-sensitive code.  |
| `--no-addons`                                        | Throw on `process.dlopen`, disable `node-addons` export condition. Pure-JS safety mode.     |
| `--unhandled-rejections=<val>`                       | `strict`, `throw`, `warn`, `none`, or `warn-with-error-code`.                               |
| `--throw-deprecation`                                | Convert deprecation warnings into errors.                                                   |
| `--no-deprecation`                                   | Silence deprecation warnings entirely.                                                      |
| `--prefer-offline`                                   | Skip registry staleness checks; resolve from the local cache.                               |
| `--prefer-latest`                                    | Always query the registry for the latest matching versions.                                 |

### Process lifetime

`--no-orphans` makes Bun exit when its parent process dies and recursively kills descendants it spawned. Use for CI runners, Electron or supervisor-launched helpers, local agents, and long-running child process trees.

```bash
bun --no-orphans run my-script
```

```toml
[run]
noOrphans = true
```

```bash
BUN_FEATURE_FLAG_NO_ORPHANS=1 bun run my-script
```

The flag is inherited by nested Bun processes. Linux uses `prctl(PR_SET_PDEATHSIG, SIGKILL)`. macOS uses parent-process kqueue watchers. It is a no-op on Windows.

### TLS and CA flags

`--use-system-ca` trusts the OS certificate store. Corporate laptops often install a private CA for a TLS-inspection proxy, so enabling this flag means the process accepts whatever certificate the corporate proxy presents. This is a deliberate trust decision, not a neutral flag. Scope it per-invocation, not as a default in deployed services, and avoid combining it with scripts that read or write long-lived credentials unless the corporate CA is in your threat model.

Do not set `NODE_TLS_REJECT_UNAUTHORIZED=0` to work around certificate errors. Bun honors it for Node compatibility, and it disables verification globally.

v1.3.14 changes: `tls.getCACertificates("system")` works without `--use-system-ca`; macOS system certificate enumeration avoids network stalls on managed devices; Windows `--use-system-ca` reads `ROOT`, `CA`, and `TrustedPeople` stores across Current User, Local Machine, Group Policy, and Enterprise locations. This improves enterprise proxy and intranet reliability without changing the trust warning above.

### Hardening profile for CLIs that handle secrets

```bash
bun --no-addons --zero-fill-buffers --unhandled-rejections=strict cli.ts
```

Disables native addon loading, zeroes unsafe buffers, fails loudly on unhandled rejections. Combine with `--no-install` in production and `Bun.secrets` for credential storage.

## Server Defaults

| Flag         | Purpose                                                                                                        |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| `--port=<n>` | Default port for `Bun.serve()` when the server object does not specify one. Also honored for HTML entrypoints. |

## Watch and Hot Reload

| Flag                | Scope                                                                     |
| ------------------- | ------------------------------------------------------------------------- |
| `--watch`           | Restart the process on file change.                                       |
| `--hot`             | In-place module re-evaluation. Preserves HTTP handlers. Server-side only. |
| `--no-clear-screen` | Keep previous output visible across reloads.                              |

See `references/quirks.md` "HMR: Three Different Mechanisms" for the full comparison with browser HMR.

## Subcommand Map

| Command                   | Purpose                                                           |
| ------------------------- | ----------------------------------------------------------------- |
| `bun run`                 | Execute a file or package script.                                 |
| `bun test`                | Test runner. See `references/test-runner.md`.                     |
| `bun x` / `bunx`          | Execute a package binary, installing if needed.                   |
| `bun repl`                | Interactive REPL.                                                 |
| `bun exec`                | Run a shell script with Bun's `$`.                                |
| `bun install` / `bun i`   | Install dependencies.                                             |
| `bun add` / `bun a`       | Add a dependency.                                                 |
| `bun remove` / `bun rm`   | Remove a dependency.                                              |
| `bun update`              | Update dependencies. Supports `-i` interactive and `--recursive`. |
| `bun audit`               | Check installed packages for known CVEs.                          |
| `bun outdated`            | List dependencies with newer versions. Supports `--recursive`.    |
| `bun link` / `bun unlink` | Register or link a local package for cross-project development.   |
| `bun publish`             | Publish to the npm registry with provenance support.              |
| `bun patch <pkg>`         | Git-friendly `node_modules` patching (replaces `patch-package`).  |
| `bun pm <subcommand>`     | Lockfile, cache, and package.json utilities.                      |
| `bun info <pkg>`          | Show registry metadata.                                           |
| `bun why <pkg>`           | Explain why a package is installed.                               |
| `bun build`               | Bundle and compile.                                               |
| `bun init`                | Scaffold a new project interactively.                             |
| `bun create <template>`   | Create from built-in template or `create-*` package.              |
| `bun upgrade`             | Upgrade Bun itself.                                               |

See `references/package-manager.md` for full `pm` subcommand coverage.
