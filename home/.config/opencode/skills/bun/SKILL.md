---
name: bun
description: >-
  Bun v1.3.14 (May 2026). Bun-first CLIs, services, dev servers, builds,
  tests, and package management. Covers every built-in API that replaces
  common npm packages (Bun.sql, Bun.redis, Bun.secrets, Bun.WebView,
  Bun.Image, Bun.cron, Bun.Glob, Bun.semver, Bun.YAML, Bun.s3, Bun.Archive,
  Bun.CSRF, parseArgs), runtime flags including --no-orphans and experimental
  HTTP/2+HTTP/3 fetch, bun test (--changed, --parallel, --shard),
  package manager (catalogs, isolated installs, security scanner, audit,
  global virtual store, patch, publish), and frontend dev server (bunfig.toml,
  Bun.serve including experimental HTTP/3, index.html entrypoints,
  import.meta.hot, Tauri+Bun, SolidJS/React/Tailwind with Bun, WebSocket/ws
  interop, Windows Bun.Terminal via ConPTY). Also covers operational
  scripts (`scripts/*.mjs` exposed via `package.json` scripts) for
  rotation/infra workflows colocated with a CLI. Corrects common agent
  misconceptions about Bun's built-in APIs.
---

# Bun (v1.3.14)

Bun is an all-in-one JS/TS toolkit: runtime, bundler, package manager, test runner, and frontend dev server with browser HMR. This skill is maintained for v1.3.14.

Docs index for agent-friendly navigation: <https://bun.sh/llms.txt>

**Top rules.** Read these before anything else:

1. If you need plugins (Tailwind, SolidJS, anything non-React), **do not use `bun build` CLI**. It does not load plugins. Use `Bun.build()` API or `bunfig.toml [serve.static]`.
2. **Browser HMR is not `bun --hot`.** `--hot` is server-side re-evaluation. Browser HMR comes from `bun ./index.html` or `Bun.serve({ development: true })`.
3. Before adding an npm dependency, check the "Built-in Replacements" table below. Most common CLI and backend stack is already in the Bun stdlib.
4. In production, always `bun install --frozen-lockfile --production` ahead of time and run with `--no-install`. Never `--analyze` on untrusted source.
5. Before adding `sharp`, check whether `Bun.Image` covers the resize, convert, metadata, placeholder, or response-body workflow.
6. HTTP/3 in `Bun.serve()` and HTTP/2/HTTP/3 `fetch()` are experimental. Do not recommend them for production unless the user explicitly asks for an experiment.
7. For supervised Bun processes on Linux/macOS, use `--no-orphans` so spawned child trees die when the parent supervisor is killed.

## Decision Guide

| Goal                                                                    | Command / approach                                                                                                   |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Zero-config frontend dev server                                         | `bun ./index.html`                                                                                                   |
| Backend + frontend in one                                               | `Bun.serve()` with HTML import + API routes                                                                          |
| Production build with plugins                                           | `Bun.build()` API (not `bun build` CLI)                                                                              |
| Production build without plugins                                        | `bun build ./index.html --outdir dist --minify`                                                                      |
| Tailwind / SolidJS transforms                                           | Add plugins via `bunfig.toml` or `Bun.build()`                                                                       |
| Server-side hot reload                                                  | `bun --hot server.ts`                                                                                                |
| Browser HMR                                                             | `bun ./index.html` or `Bun.serve()` with `development: true`                                                         |
| Image resize / convert / metadata                                       | `Bun.Image` or `Bun.file(path).image()`                                                                              |
| Supervisor-safe scripts / daemons                                       | `bun --no-orphans ...` on Linux/macOS                                                                                |
| HTTP/2 or HTTP/3 client experiment                                      | `fetch(url, { protocol: "http2" })`, `fetch(url, { protocol: "http3" })`, or experimental flags                      |
| HTTP/3 server experiment                                                | `Bun.serve({ tls, http3: true })`                                                                                    |
| Building a CLI                                                          | `Bun.build({ compile: true })` or `bun build --compile`. See [references/cli-backend.md](references/cli-backend.md). |
| Bun stdlib APIs (SQL, Redis, secrets, YAML, glob, cron, WebView, ...)   | See [references/builtin-apis.md](references/builtin-apis.md).                                                        |
| Package manager commands (why, audit, patch, catalogs, workspaces, ...) | See [references/package-manager.md](references/package-manager.md).                                                  |
| Test runner flags (`--changed`, `--parallel`, `--shard`, ...)           | See [references/test-runner.md](references/test-runner.md).                                                          |
| Runtime flags (profiling, preconnects, auto-install, ...)               | See [references/runtime-flags.md](references/runtime-flags.md).                                                      |

## Built-in Replacements for npm Packages

Bun ships most of the common CLI and backend stack. **Check here before reaching for an npm dependency.** Full details and examples in [references/builtin-apis.md](references/builtin-apis.md).

| Instead of                              | Use                                                                                                          |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `pg`, `postgres`, `mysql2`              | `Bun.sql` / `Bun.SQL`                                                                                        |
| `sharp`                                 | `Bun.Image`                                                                                                  |
| `ioredis`, `redis`                      | `Bun.redis`, `Bun.RedisClient`                                                                               |
| `keytar`                                | `Bun.secrets` (OS keychain)                                                                                  |
| `@aws-sdk/client-s3`                    | `Bun.s3`, `Bun.S3Client`                                                                                     |
| `node-cron`, `cron`                     | `Bun.cron`                                                                                                   |
| `fast-glob`, `glob`                     | `Bun.Glob`                                                                                                   |
| `semver`                                | `Bun.semver`                                                                                                 |
| `yaml`, `js-yaml`                       | `Bun.YAML`                                                                                                   |
| `toml`, `@iarna/toml`                   | `Bun.TOML`                                                                                                   |
| `json5`                                 | `Bun.JSON5`                                                                                                  |
| `puppeteer` (simple cases)              | `Bun.WebView` (headless browser via CDP)                                                                     |
| `tar`, `node-tar`                       | `Bun.Archive`                                                                                                |
| `patch-package`                         | `bun patch`                                                                                                  |
| `commander`, `yargs`                    | `parseArgs` from `node:util`                                                                                 |
| `node-fetch`                            | Built-in `fetch`                                                                                             |
| `ws` (client)                           | Built-in `WebSocket`                                                                                         |
| `marked`, `remark` (basic)              | `Bun.markdown`                                                                                               |
| `string-width`                          | `Bun.stringWidth`                                                                                            |
| `strip-ansi`, `wrap-ansi`, `slice-ansi` | `Bun.stripANSI`, `Bun.wrapAnsi`, `Bun.sliceAnsi`                                                             |
| `chalk` (color conversion only)         | `Bun.color`                                                                                                  |
| `dotenv`                                | Auto-loaded `.env`                                                                                           |
| `bcryptjs`, `argon2`                    | `Bun.password`                                                                                               |
| `crypto-js`, SHA/MD5 helpers            | `Bun.CryptoHasher`, `Bun.SHA256`, `Bun.SHA512`, etc. (SHA256+ for new code; MD5/SHA1 only for legacy compat) |
| `uuid`                                  | `Bun.randomUUIDv5`, `Bun.randomUUIDv7`                                                                       |
| `deep-equal`, `fast-deep-equal`         | `Bun.deepEquals`                                                                                             |
| `escape-html`                           | `Bun.escapeHTML`                                                                                             |
| `cheerio` (streaming)                   | `HTMLRewriter` (global)                                                                                      |
| `cli-table`                             | `Bun.inspect.table`                                                                                          |
| `which`                                 | `Bun.which`                                                                                                  |
| `ffi-napi`, `koffi`                     | `bun:ffi` (includes `cc` for inline C)                                                                       |
| `jest`, `vitest`, `tape`                | `bun:test`                                                                                                   |

## Built-in API Index

One-line summary of every `Bun.*` API and `bun:*` module. For signatures and examples, see [references/builtin-apis.md](references/builtin-apis.md).

**Servers and I/O**

- `Bun.serve` - HTTP, WebSocket, HTTPS, HTTP/2, HMR, routes
- `fetch` - built-in HTTP client; experimental `protocol: "http2" | "http3"` opt-in
- `Bun.listen` / `Bun.connect` - raw TCP
- `Bun.udpSocket` - UDP
- `Bun.dns` / `Bun.dns.prefetch` - DNS lookup and cache warming
- `Bun.FileSystemRouter` - Next.js-style file routing as an API

**Databases and storage**

- `Bun.sql` / `Bun.SQL` - unified Postgres/MySQL/SQLite
- `Bun.redis` / `Bun.RedisClient` - Redis + pub/sub
- `Bun.s3` / `Bun.S3Client` - S3-compatible object storage
- `bun:sqlite` - embedded SQLite with `columnTypes`, `deserialize` options

**Security and secrets**

- `Bun.secrets` - OS keychain
- `Bun.CSRF` - signed tokens
- `Bun.password` - argon2id and bcrypt (for passwords only)
- `Bun.CryptoHasher`, `Bun.SHA256`, `Bun.SHA512` - cryptographic hashes for new code
- `Bun.SHA1`, `Bun.MD5`, `Bun.MD4` - legacy compatibility only (broken for security use)
- `Bun.hash` family (wyhash, crc32, xxHash, cityHash, murmur32v3) - non-cryptographic only
- `Bun.randomUUIDv5`, `Bun.randomUUIDv7`

**Files, paths, processes**

- `Bun.file`, `Bun.write` - fast file I/O
- `Bun.Image` - image decode, resize, transform, encode, metadata, placeholders
- `Bun.Glob` - native globbing
- `Bun.which` - executable lookup
- `Bun.spawn`, `Bun.spawnSync` - subprocess + IPC
- `Bun.$` - shell API
- `Bun.mmap` - memory-mapped files
- `Bun.indexOfLine` - fast line scanning
- `Bun.fileURLToPath`, `Bun.pathToFileURL`

**Terminal and CLI UX**

- `Bun.stringWidth` - terminal-aware width
- `Bun.color` - ANSI / CSS / hex conversion
- `Bun.stripANSI`, `Bun.sliceAnsi`, `Bun.wrapAnsi`, `Bun.enableANSIColors`
- `Bun.Terminal` - cross-platform PTY, including Windows via ConPTY (see also `process.stdout.columns` / `setRawMode`)
- `Bun.inspect`, `Bun.inspect.table` - pretty-print
- `Bun.openInEditor` - open file in `$EDITOR`

**Data formats**

- `Bun.YAML`, `Bun.TOML`
- `Bun.JSON5`, `Bun.JSONC`, `Bun.JSONL` (streaming)
- `Bun.markdown` - GFM parser + renderer
- `Bun.Archive` - tar create/extract
- Import attributes: `with { type: "text" | "file" | "sqlite" | "json" }`

**Compression**

- `Bun.zstdCompress` / `Decompress` (sync + async)
- `Bun.gzipSync`, `Bun.gunzipSync`, `Bun.deflateSync`, `Bun.inflateSync`
- `fetch()` auto-decompresses zstd, br, gzip

**Cookies and HTTP helpers**

- `Bun.Cookie`, `Bun.CookieMap`
- `request.cookies` Map-like API on `Bun.serve`
- `HTMLRewriter` (global) - streaming HTML transform

**Scheduling and automation**

- `Bun.cron` - scheduler + parser
- `Bun.WebView` - headless browser via Chrome DevTools Protocol

**Concurrency and resources**

- Workers (cross-platform, works in compiled executables)
- `DisposableStack`, `AsyncDisposableStack` (globals)
- `Bun.sleep`, `Bun.sleepSync`, `Bun.nanoseconds`
- `Bun.peek` - inspect a Promise synchronously if already settled

**FFI and native code**

- `bun:ffi` - `dlopen` native libraries
- `bun:ffi` `cc` - inline C compiler, zero build step
- `Bun.Transpiler` - programmatic TS/JSX transpile
- `Bun.plugin` - programmatic plugin registration

**Utilities**

- `Bun.semver` - satisfies, order, compare
- `Bun.deepEquals`, `Bun.deepMatch`
- `Bun.escapeHTML`
- `Bun.embeddedFiles` - files bundled into compiled executables
- `parseArgs` from `node:util` - native CLI arg parser

**Memory and diagnostics**

- `Bun.gc`, `Bun.shrink` - force GC and release memory
- `Bun.generateHeapSnapshot`
- `bun:jsc`: `memoryUsage`, `heapStats`, `heapSize`, `estimateShallowMemoryUsageOf`

## Essential Commands

| Task                  | Command                                         |
| --------------------- | ----------------------------------------------- |
| Install dependencies  | `bun install`                                   |
| Add a dependency      | `bun add <pkg>`                                 |
| Add a dev dependency  | `bun add -d <pkg>`                              |
| Run a package script  | `bun run <script>`                              |
| Run a file directly   | `bun <file.ts>`                                 |
| Run tests             | `bun test`                                      |
| Dev server from HTML  | `bun ./index.html`                              |
| Production HTML build | `bun build ./index.html --outdir dist --minify` |

## Common Misconceptions

Agents frequently get these wrong. Read this section first.

| Claim                                             | Reality                                                                                                                                                                                                                      |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Bun has no browser HMR"                          | **Incorrect.** `Bun.serve()` with `development: true` has browser HMR. `bun ./index.html` enables it automatically.                                                                                                          |
| "Bun can't replace Vite"                          | **Mostly incorrect.** Bun covers Vite's core dev-server and bundling workflow for most projects. Plugin ecosystem is smaller; some Vite-specific APIs (`import.meta.glob`, `import.meta.env`) do not exist.                  |
| "`bun --hot` gives browser HMR"                   | **Incorrect.** `bun --hot` is server-side only. Browser HMR is via `Bun.serve()` dev mode or `bun ./index.html`.                                                                                                             |
| "Bun has no plugin system"                        | **Incorrect.** Plugin API with `onLoad`, `onResolve`, `onBeforeParse`, `onStart`. Works in `Bun.build()` API and `bunfig.toml [serve.static]`. Does NOT work in `bun build` CLI.                                             |
| "SolidJS can't work with Bun"                     | **Incorrect.** `@dschz/bun-plugin-solid` provides the Babel transform for both dev server and `Bun.build()`.                                                                                                                 |
| "Bun can't bundle HTML"                           | **Incorrect.** HTML is a first-class entrypoint. Bun processes `<script>`, `<link>`, images, and assets automatically.                                                                                                       |
| "Only React works with Bun"                       | **Incomplete.** React JSX is built-in; other frameworks work via plugins (SolidJS, Svelte, etc.) or standard JS. The plugin ecosystem is community-driven and smaller than Vite's.                                           |
| "Need `pg` / `postgres` / `mysql2` for databases" | **Incorrect.** `Bun.sql` / `Bun.SQL` is a unified built-in for Postgres, MySQL, and SQLite. Zero dependencies.                                                                                                               |
| "Need `ioredis` for Redis"                        | **Incorrect.** `Bun.redis` and `Bun.RedisClient` are built-in. 66 commands, pub/sub, auto-reconnect, faster than `ioredis`.                                                                                                  |
| "Need `sharp` for image resize/conversion"        | **Usually incorrect.** Check `Bun.Image` first for resize, conversion, metadata, placeholders, and response-body output. Keep `sharp` only when you need unsupported formats or advanced image-processing features.          |
| "Need `keytar` to store CLI secrets"              | **Incorrect.** `Bun.secrets` uses the OS keychain (macOS Keychain / Windows Credential Manager / libsecret).                                                                                                                 |
| "Need `puppeteer` for browser automation"         | **Mostly incorrect for simple cases.** `Bun.WebView` controls a headless browser via Chrome DevTools Protocol. Zero external deps on macOS.                                                                                  |
| "Need `node-cron` to schedule jobs"               | **Incorrect.** `Bun.cron` is a built-in scheduler and parser.                                                                                                                                                                |
| "Need `commander` or `yargs` to parse args"       | **Incorrect.** Use `parseArgs` from `node:util`. Native, supports multi-value flags, positionals, strict mode.                                                                                                               |
| "`bun.lockb` is still the default"                | **Outdated.** As of v1.3, the default lockfile is the text-format `bun.lock`. Older binary `bun.lockb` still works.                                                                                                          |
| "`bun test` is just a Jest clone"                 | **Incomplete.** v1.3 adds `--changed` (git-aware), `--parallel=N`, `--shard=M/N`, `--isolate`, `test.concurrent`, `test.serial`, `test.failing`, `expectTypeOf`. See [references/test-runner.md](references/test-runner.md). |
| "Plugins run during `bun install`"                | **Misleading.** Install-time lifecycle scripts are disabled by default in Bun for security. Use `trustedDependencies` in `package.json` or `bun install --trust`.                                                            |
| "HTTP/3 in Bun is production-ready"               | **Incorrect.** HTTP/3 support in `Bun.serve()` and `fetch()` is highly experimental in v1.3.14.                                                                                                                              |

### What Bun Does NOT Have (vs Vite)

- `import.meta.glob` (dynamic glob imports)
- `import.meta.env` (use `process.env` with the `env` build option instead)
- `transformIndexHtml` plugin hook (use `HTMLRewriter` in `onLoad` instead)
- Plugin support in `bun build` CLI (use `Bun.build()` API or `bunfig.toml`)
- Comparable plugin ecosystem breadth (but growing)

## Frontend Dev Server

### Zero-config

```bash
bun ./index.html              # SPA: serves as fallback for all routes
bun ./index.html ./about.html # MPA: separate routes per HTML file
bun ./**/*.html               # Glob patterns work
```

Automatic: TS/JSX transpilation, CSS bundling, HMR, source maps. Console streaming available with `--console` flag.

### Fullstack via Bun.serve()

```ts
import { serve } from "bun";
import homepage from "./index.html";

serve({
  port: 3000,
  routes: {
    "/": homepage,
    "/api/data": {
      async GET(req) {
        return Response.json({ ok: true });
      },
      async POST(req) {
        return Response.json(await req.json());
      },
    },
    "/api/items/:id": async (req) => Response.json({ id: req.params.id }),
  },
  development: {
    hmr: true, // browser HMR
    console: true, // stream browser console.log to terminal
  },
});
```

Bun processes `<script>` and `<link>` tags in the imported HTML, bundles them, and serves with HMR.

### HMR API

Bun implements a subset of Vite's `import.meta.hot` API: `accept()`, `data`, `dispose()`, and `on()`/`off()` work. `invalidate()` and `send()` are not implemented. Events also available via `vite:*` prefix for compatibility. See [references/quirks.md](references/quirks.md) for the full status table.

```ts
import.meta.hot.accept(); // self-accepting module
const root = (import.meta.hot.data.root ??= createRoot(elem)); // persist state
import.meta.hot.dispose(() => {
  cleanup();
}); // cleanup before replacement
import.meta.hot.on("bun:beforeUpdate", () => {
  /* ... */
}); // lifecycle events
```

**Important:** `import.meta.hot` must be called directly. `const hot = import.meta.hot; hot.accept()` breaks dead-code elimination.

When no module calls `import.meta.hot.accept()`, Bun falls back to full page reload.

## Bundler

### HTML entrypoints

```bash
bun build ./index.html --outdir dist --minify
```

Processes `<script>`, `<link rel="stylesheet">`, images, and assets. Outputs hashed filenames.

### JavaScript API

```ts
const result = await Bun.build({
  entrypoints: ["./index.html"], // or ["./app.ts"]
  outdir: "./dist",
  target: "browser", // "browser" | "bun" | "node"
  minify: true,
  sourcemap: "linked", // "none" | "linked" | "external" | "inline"
  splitting: true, // code splitting
  env: "PUBLIC_*", // inline env vars matching prefix
  plugins: [
    /* ... */
  ],
});
if (!result.success) {
  for (const log of result.logs) console.error(log);
}
```

### Plugin system

Plugins work in `Bun.build()` API and `bunfig.toml [serve.static]`. **Not yet supported in `bun build` CLI.** For plugin-dependent production builds, always use a build script with `Bun.build()`.

```toml
# bunfig.toml - plugins for dev server
[serve.static]
plugins = ["bun-plugin-tailwind", "./plugins/my-plugin.ts"]
```

### bunfig.toml sections

Use Bun's general config sections alongside `[serve.static]`:

| Section          | Purpose                                                                                                   |
| ---------------- | --------------------------------------------------------------------------------------------------------- |
| `[install]`      | Package manager defaults such as install behavior, registries, and dependency script trust expectations.  |
| `[test]`         | Test runner defaults such as preload files, coverage behavior, and test execution settings.               |
| `[run]`          | `bun run` execution defaults.                                                                             |
| `[serve.static]` | Frontend dev server behavior, including plugins for HTML entrypoints and HTML imported via `Bun.serve()`. |

Keep frontend plugin configuration in `[serve.static]`. Use `[install]`, `[test]`, and `[run]` for the package manager, test runner, and script defaults rather than mixing those concerns into build scripts.

Plugin shape: object with `name` and `setup(build)`. Lifecycle hooks:

- `build.onStart(callback)` - runs when bundle starts
- `build.onResolve({ filter, namespace? }, callback)` - intercept module resolution
- `build.onLoad({ filter, namespace? }, callback)` - transform module contents
- `build.onBeforeParse({ filter }, { napiModule, symbol })` - native-only pre-parse hook

```ts
import type { BunPlugin } from "bun";
const plugin: BunPlugin = {
  name: "my-plugin",
  setup(build) {
    build.onLoad({ filter: /\.custom$/ }, async (args) => ({
      contents: await Bun.file(args.path).text(),
      loader: "js",
    }));
  },
};
export default plugin;
```

## Framework Integration

### React

Built-in. No plugin needed. JSX/TSX works out of the box.

### SolidJS

Requires `@dschz/bun-plugin-solid` (Babel transform). React JSX is built-in, but SolidJS compiles to direct DOM operations and needs this plugin.

```bash
bun add -d @dschz/bun-plugin-solid @babel/core @babel/preset-typescript babel-preset-solid
```

Plugin wrapper for `bunfig.toml`:

```ts
// plugins/solid.ts
import { SolidPlugin } from "@dschz/bun-plugin-solid";
export default SolidPlugin({ generate: "dom" });
```

```toml
[serve.static]
plugins = ["./plugins/solid.ts", "bun-plugin-tailwind"]
```

### Tailwind CSS

```bash
bun add -d bun-plugin-tailwind tailwindcss
```

The plugin is required for Tailwind directives to be processed. Plain CSS bundling works without it. Reference Tailwind in CSS (`@import "tailwindcss"`), HTML (`<link rel="stylesheet" href="tailwindcss">`), or JS (`import "tailwindcss"`). Only one is needed. Tailwind v4 `@plugin` and `@theme` directives work through the plugin.

**Add `@source` if utilities are missing.** Tailwind v4's automatic content detection can fail silently inside Bun's bundler. Without `@source`, base styles load but no utility classes are generated. See quirk #5 below and [references/quirks.md](references/quirks.md).

```css
/* src/styles/global.css */
@import "tailwindcss";
@source "../../src"; /* relative to this CSS file; points at source tree */
@plugin "@kobalte/tailwindcss"; /* optional: framework-specific Tailwind plugin */
```

## Tauri Integration

Bun as frontend toolchain for Tauri desktop apps. Dev server provides HMR; production build outputs static files.

```ts
// server.ts (dev)
import { serve } from "bun";
import homepage from "./index.html";
serve({
  port: 5173,
  routes: { "/": homepage },
  development: { hmr: true, console: true },
});
```

```ts
// build.ts (production)
await Bun.build({
  entrypoints: ["./index.html"],
  outdir: "./dist",
  target: "browser",
  minify: true,
  plugins: [
    /* framework plugins */
  ],
});
```

`tauri.conf.json`:

```json
{
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:5173",
    "beforeDevCommand": "bun run dev",
    "beforeBuildCommand": "bun run build"
  }
}
```

`package.json`:

```json
{
  "scripts": {
    "dev": "bun run server.ts",
    "build": "bun run build.ts",
    "tauri": "tauri"
  }
}
```

## CLI and Backend

See [references/cli-backend.md](references/cli-backend.md) for `$` shell patterns, compiled executables, subprocess, and API server details. See [references/builtin-apis.md](references/builtin-apis.md) for the stdlib (`Bun.sql`, `Bun.redis`, `Bun.secrets`, `Bun.cron`, `Bun.WebView`, etc.). See [references/runtime-flags.md](references/runtime-flags.md) for runtime flags, profiling, auto-install, and preconnects.

### Standalone executables

`bun build --compile` produces a single binary with the Bun runtime bundled in. No runtime dependency needed.

```bash
bun build --compile ./cli.ts --outfile mycli        # current platform
bun build --compile --target=bun-windows-x64 ./cli.ts --outfile mycli  # cross-compile
bun build --compile --minify --sourcemap --bytecode ./cli.ts --outfile mycli  # production
```

Cross-compile targets: `bun-linux-x64`, `bun-linux-arm64`, `bun-windows-x64`, `bun-windows-arm64`, `bun-darwin-x64`, `bun-darwin-arm64`. Musl and CPU baseline/modern variants also available. Windows `.exe` extension added automatically. See [references/cli-backend.md](references/cli-backend.md) for the full target table.

**Startup cost warning.** Compiled binaries with heavy deps (msal, identity, ldapts) start in 700 to 900 ms warm, not the 50 ms an empty binary suggests. Lazy `await import()` does not help in compiled mode. If the target machine already has `bun` on PATH, install an `sh` shim that invokes the source entry (~110 ms warm) and ship the standalone binary only for handoff to Bun-less machines. Full scaffold in [references/cli-backend.md](references/cli-backend.md) "Standalone startup cost and the shim pattern".

### API server (no frontend)

`Bun.serve()` works as a pure API server without HTML imports:

```ts
Bun.serve({
  port: 8000,
  routes: {
    "/api/health": () => Response.json({ ok: true }),
    "/api/items/:id": (req) => Response.json({ id: req.params.id }),
  },
  fetch(req) {
    return new Response("Not found", { status: 404 });
  },
});
```

### Shell API

Bun's `$` template literal replaces subprocess calls. Cross-platform, safe by default.

```ts
import { $ } from "bun";
const result = await $`echo hello`.text(); // capture output
await $`git status`.quiet(); // suppress output
const { exitCode } = await $`cmd`.nothrow().quiet(); // no throw on error
```

### Test runner

`bun test` is Jest-compatible with Bun-specific extensions: `--changed` (git-aware), `--parallel=N`, `--shard=M/N`, `--isolate`, `test.concurrent`, `test.serial`, `test.failing`, `expectTypeOf`. Full flag and modifier reference in [references/test-runner.md](references/test-runner.md).

```ts
import { test, expect, mock, describe, beforeAll } from "bun:test";
test("example", () => {
  expect(2 + 2).toBe(4);
});
```

### Package manager

`bun install`, `bun add`, `bun why`, `bun audit`, `bun publish`, `bun patch`, `bun pm pkg/pack/version`, catalogs, isolated installs, security scanner, `minimumReleaseAge`. Full coverage in [references/package-manager.md](references/package-manager.md).

Production CI/Docker checklist (from `references/package-manager.md` "Production Install Checklist"):

```bash
bun install --frozen-lockfile --production
bun --no-install run start         # never let runtime silently fetch packages
```

Do not use `bun install --analyze` on untrusted source. See the supply-chain warning in `references/package-manager.md`.

## CSS and tsconfig.json

**CSS:** Bun has a native CSS parser. Supports `@import` bundling, asset URL rewriting with content hashes, minification. CSS imported from JS (`import "./styles.css"`) generates a co-located `.css` output file. For the dev server, reference CSS from HTML `<link>` tags.

**tsconfig.json:** Bun reads `paths` (replaces Vite's `resolve.alias`), `jsx`/`jsxFactory`/`jsxImportSource`, and `experimentalDecorators`. No separate bundler config needed. For Bun-specific type definitions (e.g. `Bun.serve`, `Bun.build`, `bun:test`), add `"types": ["bun-types"]` to `compilerOptions`; this is only needed when your editor or `tsc` does not already recognize Bun globals.

## Known Quirks

See [references/quirks.md](references/quirks.md) for detailed workarounds.

0. **HTTP/3 and HTTP/2 fetch are experimental** - `Bun.serve({ tls, http3: true })` and `fetch(url, { protocol: "http2" | "http3" })` are useful for experiments, not default production recommendations.

1. **WebSocket: Bun's native API differs from `ws`** - Bun's server-side WebSocket is integrated into `Bun.serve()` and is NOT API-compatible with the `ws` npm package. If a dependency expects `ws`-style server objects or Node.js HTTP upgrade handling, you do not need to leave Bun. Instead, use `ws` with Node's `http`/`https` modules inside Bun; Bun's Node compatibility layer supports this pattern. See [references/quirks.md](references/quirks.md) for the specific API mismatch details.

2. **Plugin CLI gap** - `bun build` CLI does not load plugins. Use `Bun.build()` API or `bunfig.toml [serve.static]`.

3. **`bun --hot` is server-side only** - Never recommend `bun --hot` for browser HMR. Browser HMR requires `Bun.serve()` with `development: true` or `bun ./index.html`.

4. **No `import.meta.env`** - Use `process.env` with the `env` option in `Bun.build()` or `bunfig.toml` to inline environment variables at build time.

5. **Tailwind v4 content detection can fail silently in Bun's bundler** - `bun-plugin-tailwind` may generate base/preflight styles but zero utility classes when Tailwind's oxide scanner does not auto-detect source files. If utility classes are missing, add `@source "../../src"` (or appropriate relative path) in your CSS. Without it, the app looks unstyled despite no errors. See [references/quirks.md](references/quirks.md).

6. **`--no-orphans` is platform-specific** - it protects Linux/macOS supervised child trees, but is a no-op on Windows.
