# Bun Quirks and Workarounds

Detailed reference for known Bun edge cases and their solutions.

## WebSocket Compatibility

### Core issue: API shape mismatch

Bun's server-side WebSocket is integrated into `Bun.serve()`:

```ts
const ALLOWED_ORIGINS = new Set(["https://app.example.com"]);

Bun.serve({
  fetch(req, server) {
    if (req.headers.get("upgrade") === "websocket") {
      // Reject Cross-Site WebSocket Hijacking. Cookies are auto-sent by browsers
      // on ws:// upgrades from any origin, so origin-check before upgrade.
      const origin = req.headers.get("origin") ?? "";
      if (!ALLOWED_ORIGINS.has(origin)) {
        return new Response("forbidden", { status: 403 });
      }
      if (
        server.upgrade(req, {
          data: {
            /* per-connection context */
          },
        })
      )
        return;
    }
    return new Response("Not found", { status: 404 });
  },
  websocket: {
    open(ws) {
      /* ... */
    },
    message(ws, message) {
      /* ... */
    },
    close(ws, code, reason) {
      /* ... */
    },
  },
});
```

This is a different API from the `ws` npm package. Libraries expecting `new WebSocketServer()`, `wss.on("connection")`, or Node.js `http.Server` upgrade handling will not work with Bun's native WebSocket.

### When to use ws instead of Bun's built-in

Use the `ws` npm package **inside Bun** (via Bun's Node.js compatibility layer) when:

- A dependency wraps WebSocket with `ws`-specific server objects or event patterns
- You need the Node.js `http`/`https` upgrade pipeline (e.g. custom headers, authentication during upgrade)
- A protocol library expects specific `ws` binary frame handling

You do not need to leave the Bun runtime. Bun runs `ws` and Node's `http` module well enough for this pattern:

```ts
// Inside Bun: using ws + Node http instead of Bun.serve() websocket
import { createServer } from "http";
import { WebSocketServer } from "ws";

const server = createServer();
const wss = new WebSocketServer({ server });
wss.on("connection", (ws) => {
  ws.on("message", (data) => {
    /* handle */
  });
});
server.listen(8080);
```

```bash
bun add ws
bun add -d @types/ws
```

### Client-side differences

Bun's global `WebSocket` class mostly matches the browser spec. Known differences:

- Binary messages arrive as `ArrayBuffer` (Bun) vs `Buffer` (`ws` in Node.js)
- Error event payload shapes may differ from `ws`

v1.3.14 fix: `perMessageDeflate: false` is now respected in WebSocket upgrade requests for both `ws` and global `WebSocket`. Bun no longer advertises `Sec-WebSocket-Extensions: permessage-deflate` when extensions are disabled, and now fails the handshake if a server responds with extensions the client did not offer.

## Experimental HTTP/2 and HTTP/3

### `Bun.serve()` HTTP/3

HTTP/3 over QUIC is highly experimental. Do not recommend it for production unless explicitly requested.

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

Requirements and behavior:

- Requires TLS.
- Binds TCP for HTTP/1.1+2 and UDP for HTTP/3 on the same port.
- Adds `Alt-Svc: h3=":<port>"; ma=86400` to HTTP/1.1 and HTTP/2 responses so browsers can discover HTTP/3.

Limitations:

- WebSocket over HTTP/3 is not supported.
- 0-RTT is disabled.
- Unix sockets skip the HTTP/3 listener.
- No trailer support.
- No `Expect: 100-continue` support.

### HTTP/2 and HTTP/3 `fetch()`

The HTTP/2 and HTTP/3 clients are experimental and opt-in.

```ts
await fetch("https://example.com", { protocol: "http2" });
await fetch("https://example.com", { protocol: "http3" });
```

Accepted aliases include `"h2"`, `"h1"`, and `"h3"`. Global enablement:

```bash
bun --experimental-http2-fetch app.ts
bun --experimental-http3-fetch app.ts
BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP2_CLIENT=1 bun app.ts
BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP3_CLIENT=1 bun app.ts
```

HTTP/3 Alt-Svc automatic upgrades require the HTTP/3 flag/env var. Pinned per-request protocols do not require the global flag.

## HMR: Three Different Mechanisms

### 1. `bun --hot` (server-side module re-evaluation)

Re-evaluates changed modules without restarting the process. HTTP handlers update in place. No browser involvement. No page reload.

```bash
bun --hot server.ts
```

### 2. `bun --watch` (full process restart)

Restarts the entire Bun process when files change. Heavier than `--hot`.

```bash
bun --watch server.ts
```

### 3. Browser HMR (via dev server)

Injects a WebSocket client into served HTML. Receives update notifications and patches modules in the browser. Only available through:

- `bun ./index.html` (zero-config)
- `Bun.serve()` with `development: true` or `development: { hmr: true }`

**Never recommend `bun --hot` when the user wants browser HMR.**

## import.meta.hot Limitations

| Method           | Status                                     |
| ---------------- | ------------------------------------------ |
| `accept()`       | Works                                      |
| `data`           | Works                                      |
| `dispose()`      | Works                                      |
| `on()` / `off()` | Works                                      |
| `decline()`      | No-op (Vite compat)                        |
| `prune()`        | Registered but callback never called (WIP) |
| `invalidate()`   | Not implemented                            |
| `send()`         | Not implemented                            |

**Must be called directly:** `import.meta.hot.accept()` works. `const hot = import.meta.hot; hot.accept()` does not (breaks dead-code elimination).

**`import.meta.hot.data`** is `{}` in production, enabling clean DCE: `{}.prop ??= value` minifies to `value`.

**Events:** `bun:beforeUpdate`, `bun:afterUpdate`, `bun:beforeFullReload`, `bun:beforePrune`, `bun:error`, `bun:ws:disconnect`, `bun:ws:connect`. Also available with `vite:` prefix.

## Plugin System Gaps

### CLI vs API

| Surface                      | Plugins supported? |
| ---------------------------- | ------------------ |
| `Bun.build()` API            | Yes                |
| `bunfig.toml [serve.static]` | Yes (dev server)   |
| `bun build` CLI              | No                 |

For production builds that need plugins, use a build script:

```ts
// build.ts
await Bun.build({
  entrypoints: ["./index.html"],
  outdir: "./dist",
  plugins: [
    /* your plugins */
  ],
});
```

### Other plugin limitations

- `onBeforeParse` is native-only (Rust/C NAPI modules)
- `onLoad` `.defer()` can only be called once per callback
- No equivalent of Vite's `transformIndexHtml` hook; use `HTMLRewriter` in `onLoad` for `.html` files
- No first-class virtual module API; use `onResolve` + `onLoad` to achieve the same effect

## CSS Processing

### @import resolution

Bun resolves `@import` paths relative to the importing CSS file.

### Tailwind integration

With `bun-plugin-tailwind`:

- `@import "tailwindcss"` works
- `@theme` directives work
- `@plugin` directives work (loads Tailwind plugins like `@kobalte/tailwindcss`)
- `@apply` works

Without the plugin, Tailwind directives are not processed. Plain CSS bundling works without any plugin.

### Tailwind v4 content detection can fail silently

**Important quirk.** When `bun-plugin-tailwind` runs inside Bun's bundler (both `Bun.serve()` HTML routes and `Bun.build()`), Tailwind v4's automatic content detection may not find source files. The result is subtle: the CSS file loads, base/preflight styles apply (dark backgrounds, resets), but no project-specific utility classes are generated. No error is logged.

**Symptoms:** App renders with correct colors from CSS custom properties and base styles, but Tailwind utility classes (`flex-col`, `h-screen`, `p-4`, `gap-3`, etc.) have no effect. The bundled CSS is noticeably smaller than expected, containing only base/preflight layers.

**Fix:** Add an explicit `@source` directive in your CSS to tell Tailwind where to scan for utility classes:

```css
/* src/styles/global.css */
@import "tailwindcss";
@source "../../src"; /* path relative to this CSS file */
@plugin "@kobalte/tailwindcss";
```

The `@source` path is relative to the CSS file. Point it at the directory containing your `.tsx`/`.jsx`/`.ts`/`.html` templates. Multiple `@source` directives can be used if templates span several directories.

**Likely cause:** Tailwind v4 uses `@tailwindcss/oxide` for content scanning. The oxide scanner resolves the project root from `build.config?.root ?? process.cwd()`. In Bun's bundler plugin context, this resolution may not reliably walk the source tree. The `@source` directive bypasses auto-detection entirely. This has been observed on Windows but may also affect other platforms.

### CSS-in-JS imports

`import "./styles.css"` in JavaScript works in Bun's bundler. It generates a co-located CSS output file. This differs from Vite's CSS module behavior.

## Environment Variables

- `process.env` works at runtime
- For frontend builds, use `env: "inline"` or `env: "PUBLIC_*"` in `Bun.build()` to inline at build time
- `import.meta.env` does NOT exist in Bun (unlike Vite); use `process.env` with the env build option
- `.env` files are loaded automatically by Bun runtime

## Package Manager and CLI Gotchas

### Flag placement

Put Bun's own flags before the file or subcommand they should affect:

```bash
bun --watch server.ts
bun --hot server.ts
```

`bun server.ts --watch` passes `--watch` to your program instead of enabling Bun watch mode.

### Dependency lifecycle scripts

Do not assume Bun will run every dependency lifecycle script the same way npm or pnpm would. If a package depends on an install or postinstall step, check whether it must be explicitly trusted before debugging the package itself.

- Packages that need install scripts may require trust configuration
- If a native addon or generated binary looks half-installed, check script trust first

### Phantom dependencies

Do not rely on undeclared transitive dependencies. If code imports a package, add it directly with `bun add` even if it currently resolves through another dependency in `node_modules`.

### Auto-install in production

Bun can auto-install missing packages when a `bun.lock` is present. That is convenient for local development and risky in CI or production. In deployed environments, run `bun install` ahead of time and treat missing dependencies as a build or release error.

## fs.watch

v1.3.14 rewrote the POSIX `fs.watch()` backend to use native OS watchers directly: inotify on Linux, FSEvents on macOS, and kqueue on FreeBSD.

Practical fixes:

- Linux recursive watches now track directories created after the watch starts.
- Deleted-and-recreated watched files emit `change` events again.
- macOS no longer starts duplicate watcher threads for directory watches.

This matters for dev servers, file-watching agents, and tools that create directories after startup.

## `using` / `await using`

When targeting Bun, v1.3.14 no longer lowers `using` and `await using` into helper calls because JavaScriptCore supports Explicit Resource Management natively. This applies to `bun run`, `Bun.Transpiler({ target: "bun" })`, and `bun build --target=bun` including compiled and bytecode builds.

Other targets (`browser`, `node`) still lower as before. This also fixes previous CommonJS build output problems where helper imports could be injected into `.cjs` wrappers.

## Module Resolution

### tsconfig.json paths

Bun reads `tsconfig.json` `paths` for module resolution at both runtime and bundle time. No bundler-specific alias config needed. This replaces Vite's `resolve.alias`.

### node_modules

- Reads `exports` and `imports` fields in package.json
- Supports `bun` export condition (checked before `default`)
- Auto-installs missing packages if `bun.lock` exists (can be disabled)

## Build Output Differences from Vite

- No `manifest.json` generated by default
- HTML output typically combines `<script>` tags into one and `<link>` tags into one (may vary with splitting and asset configuration)
- Asset hashing format differs from Vite
- No `import.meta.glob`
- No `import.meta.env`; use `process.env` with env build option
