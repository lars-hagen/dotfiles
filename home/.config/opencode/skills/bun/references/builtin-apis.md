# Bun Built-in APIs

Complete reference for `Bun.*` globals and `bun:*` modules in v1.3.14.

**Use this file first.** Before reaching for an npm package, check if Bun already ships it. Most common CLI and backend needs are covered by the built-ins below.

## Replacement Table

| Instead of                                | Use                                                   | Notes                                                                            |
| ----------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| `pg`, `postgres`, `mysql2`                | `Bun.sql` / `Bun.SQL`                                 | Unified Postgres, MySQL, SQLite tagged-template API.                             |
| `sharp`                                   | `Bun.Image`                                           | Built-in resize, convert, metadata, placeholders, and response-body integration. |
| `ioredis`, `redis`                        | `Bun.redis`, `Bun.RedisClient`                        | 66 commands, pub/sub, auto-reconnect.                                            |
| `keytar`                                  | `Bun.secrets`                                         | Native OS keychain (macOS/Windows/libsecret).                                    |
| `@aws-sdk/client-s3`                      | `Bun.s3`, `Bun.S3Client`                              | Native S3 bindings.                                                              |
| `node-cron`                               | `Bun.cron`                                            | Scheduler + parser.                                                              |
| `fast-glob`, `glob`                       | `Bun.Glob`                                            | Native.                                                                          |
| `semver`                                  | `Bun.semver`                                          | Full semver API.                                                                 |
| `yaml`, `js-yaml`                         | `Bun.YAML`                                            | 90%+ of the official test suite.                                                 |
| `toml`, `@iarna/toml`                     | `Bun.TOML`                                            | Parse + stringify + import.                                                      |
| `json5`                                   | `Bun.JSON5`                                           | Parse + import.                                                                  |
| `json-with-comments`                      | `Bun.JSONC`                                           | Parse.                                                                           |
| `ndjson`, streaming JSONL                 | `Bun.JSONL`                                           | Streaming parser.                                                                |
| `puppeteer` (simple cases)                | `Bun.WebView`                                         | Chrome DevTools Protocol. Zero deps on macOS.                                    |
| `tar`, `node-tar`                         | `Bun.Archive`                                         | Tar create/extract.                                                              |
| `patch-package`                           | `bun patch`                                           | Git-friendly.                                                                    |
| `commander`, `yargs` (arg parsing)        | `node:util` `parseArgs`                               | Native.                                                                          |
| `node-fetch`                              | Built-in `fetch`                                      | Native, with streaming.                                                          |
| `ws` (client)                             | Built-in `WebSocket`                                  | Native.                                                                          |
| `marked`, `remark` (basic)                | `Bun.markdown`                                        | GFM.                                                                             |
| `string-width`                            | `Bun.stringWidth`                                     | Terminal-aware.                                                                  |
| `strip-ansi`, `wrap-ansi`, `slice-ansi`   | `Bun.stripANSI`, `Bun.wrapAnsi`, `Bun.sliceAnsi`      | Native.                                                                          |
| `chalk` (color conversion)                | `Bun.color`                                           | ANSI / CSS / hex conversion.                                                     |
| `dotenv`                                  | Auto-loaded `.env`                                    | Built-in runtime.                                                                |
| `crypto-js`, `bcryptjs`                   | `Bun.password`, `Bun.CryptoHasher`, `Bun.SHA256` etc. | Argon2id/bcrypt built-in.                                                        |
| `uuid`                                    | `Bun.randomUUIDv5`, `Bun.randomUUIDv7`                | UUIDv5 and v7 native.                                                            |
| `deep-equal`, `fast-deep-equal`           | `Bun.deepEquals`                                      | Native.                                                                          |
| `escape-html`                             | `Bun.escapeHTML`                                      | Native.                                                                          |
| `node-html-parser`, `cheerio` (streaming) | `HTMLRewriter`                                        | Streaming DOM-free transform.                                                    |
| `ffi-napi`, `koffi`                       | `bun:ffi` including `cc`                              | FFI + inline C.                                                                  |
| `tape`, `vitest`, `jest`                  | `bun:test`                                            | Jest-compatible with concurrency + `--changed` + sharding.                       |

## Databases

### `Bun.sql` and `Bun.SQL` (unified SQL)

One API covers PostgreSQL, MySQL, MariaDB, and SQLite. Tagged-template syntax auto-parameterizes values.

```ts
import { sql, SQL } from "bun";

// Default: reads connection from PG/MYSQL/DATABASE_URL env vars.
const users = await sql`SELECT id, name FROM users WHERE age >= ${18}`;

// Multiple databases side by side.
const pg = new SQL("postgres://user:pass@host/db");
const mysql = new SQL("mysql://user:pass@host/db");
const lite = new SQL("sqlite://./data.db");

// Insert/update helpers.
const user = { name: "Alice", email: "a@b.com" };
await sql`INSERT INTO users ${sql(user)}`;
await sql`INSERT INTO users ${sql(user, "name")}`; // only the "name" column
await sql`UPDATE users SET ${sql(user, "email")} WHERE id = ${1}`;

// WHERE IN with arrays.
await sql`SELECT * FROM users WHERE id IN ${sql([1, 2, 3])}`;

// PostgreSQL array helper.
await sql`INSERT INTO posts (tags) VALUES (${sql.array(["a", "b"], "TEXT")})`;

// Multi-statement via simple protocol.
await sql`
  CREATE TABLE a (id INT);
  CREATE TABLE b (id INT);
`.simple();
```

Production options via `bunfig.toml` or constructor:

```ts
const pg = new SQL({
  url: "postgres://...",
  max: 20, // connection pool size
  prepare: false, // for PgBouncer transaction mode
  path: "/tmp/.s.PGSQL.5432", // Unix socket
  connection: {
    search_path: "app_schema",
    statement_timeout: "30s",
    application_name: "myapp",
  },
});
```

Error classes are exported for typed error handling:

```ts
import { SQL, PostgresError, MySQLError, SQLiteError } from "bun";
```

### `Bun.redis` and `RedisClient`

```ts
import { redis, RedisClient } from "bun";

// Default client uses REDIS_URL or localhost:6379.
await redis.set("key", "value");
const v = await redis.get("key");
await redis.expire("key", 60);
await redis.hset("user:1", { name: "Alice", age: "30" });

// Custom instance.
const r = new RedisClient("redis://host:6379");

// Pub/Sub: subscribers cannot publish, so duplicate the connection.
const publisher = await r.duplicate();
await r.subscribe("channel", (message, channel) => {
  /* ... */
});
await publisher.publish("channel", "hello");
```

Supports 66 commands including hashes, lists, sets, sorted sets, streams (partial), and scripting. Auto-reconnects, queues commands during disconnects. Significantly faster than `ioredis`.

### `bun:sqlite`

```ts
import { Database } from "bun:sqlite";

const db = new Database("data.db", { create: true, strict: true });

db.run(`CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)`);
db.query("INSERT INTO users (name) VALUES (?)").run("Alice");

const rows = db.query("SELECT * FROM users").all();
const one = db.query("SELECT * FROM users WHERE id = ?").get(1);

// Type introspection (v1.3+).
const stmt = db.query("SELECT id, name FROM users");
stmt.declaredTypes; // ["INTEGER", "TEXT"]  - from CREATE TABLE
stmt.columnTypes; // ["integer", "text"]  - actual storage

// Serialize and deserialize with options.
const buf = db.serialize();
const clone = Database.deserialize(buf, {
  readonly: true,
  strict: true,
  safeIntegers: true,
});
```

Options:

- `strict: true` - throw on missing bind parameters. Use for production code.
- `safeIntegers: true` - return `bigint` for integers outside safe integer range.
- `readonly: true` - open read-only.

**Untrusted buffers.** `Database.deserialize()` accepts any SQLite image. Do not deserialize buffers from network uploads or user input without a size cap and `readonly: true`. A crafted image can embed triggers/views and exercise historical SQLite parser CVEs. For file uploads, validate shape, enforce a size limit, open read-only, and only run queries you control (not dynamic SQL sourced from `sqlite_master`).

### Embedding a SQLite database

```ts
import seed from "./seed.db" with { type: "sqlite", embed: "true" };
// seed is a Database instance loaded from the embedded file.
```

Ship read-only lookup data inside a compiled executable.

## Secrets

### `Bun.secrets`

OS-native credential storage. macOS Keychain, Windows Credential Manager, libsecret on Linux. No in-process storage of sensitive data.

```ts
import { secrets } from "bun";

await secrets.set({ service: "mycli", name: "api-key", value: "sk-..." });
const key = await secrets.get({ service: "mycli", name: "api-key" });
await secrets.delete({ service: "mycli", name: "api-key" });
```

Use for CLIs that persist tokens, credentials, or OAuth refresh tokens. Replaces `keytar`.

### `Bun.CSRF`

```ts
import { CSRF } from "bun";

// Signing secret from env or Bun.secrets. Never a literal. Rotate periodically.
const CSRF_SECRET = process.env.CSRF_SECRET;
if (!CSRF_SECRET || CSRF_SECRET.length < 32) {
  throw new Error("CSRF_SECRET must be set to at least 32 random bytes");
}

function issue(sessionId: string) {
  // Bind the token to the user's session so it cannot be replayed across users.
  return CSRF.generate(CSRF_SECRET, { expiresIn: 3600, encoding: "base64url" });
}

function check(token: string, sessionId: string) {
  return CSRF.verify(token, { secret: CSRF_SECRET });
}
```

HMAC-based, signed, optionally time-bound. Load the signing secret from `Bun.secrets`, environment, or a secret manager; never a literal. Bind tokens to the session identifier so they cannot be replayed across users. Pair with `httpOnly`+`secure`+`sameSite: "strict"` cookies for defense-in-depth.

## Object Storage

### `Bun.s3` and `S3Client`

```ts
import { s3, S3Client } from "bun";

// Default client uses env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET.
const file = s3.file("path/to/object.json");
await file.write(JSON.stringify({ ok: true }), { storageClass: "STANDARD_IA" });
const text = await file.text();

// List objects.
for (const obj of await s3.list({ prefix: "uploads/" })) {
  console.log(obj.key, obj.size);
}

// Custom client (S3-compatible: MinIO, R2, B2, Wasabi).
const r2 = new S3Client({
  endpoint: "https://accountid.r2.cloudflarestorage.com",
  accessKeyId: "...",
  secretAccessKey: "...",
  bucket: "my-bucket",
  virtualHostedStyle: true,
});
```

Supports presigned URLs, multipart uploads, and streaming. See the S3 docs for complete options.

## Secrets, Hashing, Randomness

### `Bun.password`

```ts
const hash = await Bun.password.hash("my-password"); // argon2id default
const ok = await Bun.password.verify("my-password", hash);
```

Prefer `argon2id` for new services. Parameters below track OWASP's Password Storage guidance; re-evaluate yearly as hardware improves.

```ts
// argon2id - preferred.
await Bun.password.hash(pw, {
  algorithm: "argon2id",
  memoryCost: 65536, // 64 MiB (OWASP higher-memory profile)
  timeCost: 3,
});

// bcrypt - legacy-compatible. cost 12 is about 250 ms on a 2024 server CPU.
// Raise cost as hardware improves; do not drop below 10.
await Bun.password.hash(pw, { algorithm: "bcrypt", cost: 12 });
```

### `Bun.CryptoHasher`

Streaming hasher supporting all common algorithms.

```ts
const hasher = new Bun.CryptoHasher("sha256");
hasher.update("hello ");
hasher.update("world");
const digest = hasher.digest("hex"); // or "base64", or Buffer
```

**Non-cryptographic hashes.** Fast, for deduplication, partitioning, bloom filters, checksums. Never use for passwords, signatures, session tokens, or integrity against an attacker.

```ts
Bun.hash("hello"); // wyhash -> number
Bun.hash.wyhash("hello");
Bun.hash.crc32("hello");
Bun.hash.xxHash32("hello");
Bun.hash.xxHash64("hello");
Bun.hash.cityHash32("hello");
Bun.hash.cityHash64("hello");
Bun.hash.murmur32v3("hello");
```

**Cryptographic hashes.** For signatures, HMAC, content integrity against an attacker. Use `SHA256` or `SHA512` for new code. `MD5`, `SHA1`, and `MD4` are cryptographically broken; keep them only for compatibility with legacy protocols.

```ts
new Bun.SHA256().update("hello").digest("hex");
new Bun.SHA512().update("hello").digest("hex");
// Legacy only: SHA1, SHA224, SHA384, SHA512_256, MD4, MD5
```

For passwords, use `Bun.password` (argon2id/bcrypt). Never use raw hashes.

### `Bun.randomUUIDv7` and `Bun.randomUUIDv5`

```ts
Bun.randomUUIDv7(); // time-sortable, ideal for DB primary keys
Bun.randomUUIDv7("hex", Date.now()); // explicit encoding and timestamp
Bun.randomUUIDv5("name", namespaceUuid); // namespaced, deterministic
```

UUIDv7 is preferable to v4 for database keys because it sorts chronologically, improving B-tree index locality.

## Terminal and CLI UX

### `Bun.stringWidth`

Monospace width taking into account zero-width joiners, emoji, CJK characters, ANSI escapes.

```ts
Bun.stringWidth("\x1b[31mhello\x1b[0m"); // 5 (ANSI stripped)
Bun.stringWidth("👨‍👩‍👧"); // 2 (emoji family)
```

Use for table rendering, truncation, progress bars. Replaces `string-width`.

### ANSI utilities

```ts
Bun.stripANSI("\x1b[31mred\x1b[0m"); // "red"
Bun.sliceAnsi("\x1b[31mhello world\x1b[0m", 0, 5); // "\x1b[31mhello\x1b[0m"
Bun.wrapAnsi("long string...", 80); // word-wrap respecting ANSI
Bun.enableANSIColors.stdout; // boolean, respects NO_COLOR and TTY
Bun.enableANSIColors.stderr;
```

### `Bun.color`

Convert and emit colors in any format.

```ts
Bun.color("red", "ansi"); // "\x1b[31m"
Bun.color("#ff5500", "ansi-256"); // "\x1b[38;5;202m"
Bun.color("rgb(255 0 0)", "ansi-16m"); // 24-bit ANSI
Bun.color("red", "css"); // "rgb(255, 0, 0)"
Bun.color("red", "number"); // 16711680
Bun.color({ r: 255, g: 0, b: 0 }, "hex"); // "#ff0000"
```

### `Bun.inspect` and `Bun.inspect.table`

```ts
Bun.inspect(obj, { depth: 2, colors: true, sorted: true });
console.log(
  Bun.inspect.table([
    { id: 1, name: "Alice", age: 30 },
    { id: 2, name: "Bob", age: 25 },
  ]),
);
```

Table output aligns columns, handles Unicode width, colorizes by type. Use for CLI reports without `cli-table`.

### `Bun.openInEditor`

```ts
Bun.openInEditor("./src/index.ts", { editor: "code", line: 42, column: 10 });
```

Respects `$EDITOR` / `$VISUAL`. Supports `code`, `vim`, `subl`, `atom`. Useful for error handlers, `git commit` style prompts, log -> source navigation.

### `Bun.Terminal`

Cross-platform pseudo-terminal utility. In v1.3.14 it works on Windows via ConPTY as well as POSIX PTYs.

```ts
const terminal = new Bun.Terminal({
  cols: 80,
  rows: 24,
  onData(data) {
    process.stdout.write(data);
  },
});

const proc = Bun.spawn({
  cmd: [process.platform === "win32" ? "cmd.exe" : "sh"],
  terminal,
});

await proc.exited;
terminal.close();
```

Windows caveats: `inputFlags`, `outputFlags`, `localFlags`, and `controlFlags` are no-ops; ConPTY may re-encode escape sequences; input without a child process is buffered rather than echoed. For simple terminal size and raw mode, `process.stdout.columns` / `process.stdout.rows` and `process.stdin.setRawMode(true)` are still often enough.

## Images

### `Bun.Image`

Built-in image processing for JPEG, PNG, WebP, GIF, and BMP across platforms, with HEIC, AVIF, and TIFF depending on OS support. Use before adding `sharp` for common server-side image operations.

```ts
await Bun.file("photo.jpg")
  .image()
  .resize(1024, 1024, { fit: "inside" })
  .rotate(90)
  .webp({ quality: 85 })
  .write("thumb.webp");

const meta = await Bun.file("hero.jpg").image().metadata();
const placeholder = await Bun.file("hero.jpg").image().placeholder();
```

Inputs: path strings, `ArrayBuffer`/TypedArray, `Blob`, `BunFile`, `S3File`, and `data:` URLs. You can start with `new Bun.Image(input)`, `Bun.file(path).image()`, or `blob.image()`.

Transforms: `.resize(w, h?, { filter, fit, withoutEnlargement })`, `.rotate(90 | 180 | 270)`, `.flip()`, `.flop()`, `.modulate({ brightness, saturation })`.

Resize filters: `nearest`, `box`, `bilinear`, `cubic`, `mitchell`, `lanczos2`, `lanczos3`, `mks2013`, `mks2021`.

Outputs: `.jpeg()`, `.png()`, `.webp()`, `.heic()`, `.avif()`, then `.bytes()`, `.buffer()`, `.blob()`, `.toBase64()`, `.dataurl()`, `.placeholder()`, `.metadata()`, or `.write(dest)`.

`Bun.Image` instances can be response/request bodies and set `Content-Type` automatically:

```ts
return new Response(new Bun.Image(upload).resize(200).jpeg());
```

Platform caveat: JPEG, PNG, WebP, GIF, and BMP are portable. HEIC, AVIF, and TIFF use OS backends and vary by platform.

### `parseArgs` (from `node:util`)

Native CLI argument parser. No `commander`/`yargs` needed.

```ts
import { parseArgs } from "node:util";

const { values, positionals } = parseArgs({
  args: process.argv.slice(2),
  options: {
    port: { type: "string", short: "p", default: "3000" },
    verbose: { type: "boolean", short: "v" },
    tag: { type: "string", multiple: true },
  },
  strict: true,
  allowPositionals: true,
});
```

## Data Formats

### `Bun.YAML`

```ts
import { YAML } from "bun";

YAML.parse("key: value");
YAML.stringify({ key: "value" });

// Also works as an import.
import config from "./config.yaml";
```

90%+ of the official yaml-test-suite passes. Missing: literal chomping (`|+`, `|-`) edge cases and cyclic references.

`Bun.YAML.parse` is a pure data parser and does not instantiate arbitrary types, unlike Ruby's default `YAML.load`, PyYAML's default mode, or SnakeYAML with default typing enabled. Safe to call on untrusted input subject to normal input-size limits.

### `Bun.TOML`

```ts
import { TOML } from "bun";
TOML.parse(`[server]\nport = 3000`);

// And as an import.
import cfg from "./config.toml";
```

### `Bun.JSON5`, `Bun.JSONC`, `Bun.JSONL`

```ts
Bun.JSON5.parse(`{ unquoted: "trailing comma", }`);
Bun.JSONC.parse(`{ /* with comments */ "key": "value" }`);
await Bun.JSONL.parse(readableStream); // streaming newline-delimited JSON
```

Matching import attributes:

```ts
import cfg from "./config.json5";
import cfg from "./config.jsonc";
```

### `Bun.markdown`

```ts
import { markdown } from "bun";
markdown.html("# Hello\n**world**"); // <h1>Hello</h1>\n<p><strong>world</strong></p>
markdown.ansi("# Hello\n**world**"); // terminal-colored rendering (ideal for CLI help output)
markdown.render("# Hello"); // plain-text fallback
markdown.react("# Hello"); // React element tree
```

GFM extensions: tables, strikethrough, task lists, autolinks. `markdown.ansi()` is especially useful for CLI tools that display formatted help, release notes, or remote changelogs directly in the terminal.

### `Bun.Archive` (tar)

Create, read, and extract tar archives. Supports optional gzip compression.

```ts
// Create an archive from files.
const archive = new Bun.Archive(
  {
    "README.md": "# My Project",
    "src/index.ts": "console.log('hi');",
    "nested/file.bin": new Uint8Array([1, 2, 3]),
  },
  { compress: "gzip", level: 9 },
); // compression optional

await Bun.write("release.tar.gz", archive);

// Read an existing archive.
const tarball = await Bun.file("pkg.tar.gz").bytes();
const a = new Bun.Archive(tarball);

// Extract to disk with optional glob filtering.
const count = await a.extract("./out", { glob: ["src/**", "!**/*.test.ts"] });

// Read contents without extracting.
const files = await a.files("**/*.ts"); // Map<string, File>
for (const [path, file] of files) {
  console.log(path, await file.text());
}

// Get archive bytes directly.
const bytes = await a.bytes(); // Uint8Array
const blob = await a.blob(); // Blob
```

Security: `extract()` rejects absolute paths, UNC paths, and `..` traversal in member names. For archives from untrusted sources, also consider symlink/hardlink targets (extractor behavior varies), file modes including setuid/setgid bits, and decompression-bomb ratios. For high-risk input:

```ts
const MAX_PER_FILE = 50 * 1024 * 1024; // 50 MiB
const a = new Bun.Archive(untrustedBytes);
for (const [path, file] of await a.files()) {
  if (file.size > MAX_PER_FILE) throw new Error("oversize member");
}
await a.extract("./sandbox-dir");
```

File content types supported by the constructor: `string`, `Blob`, `Uint8Array`, `ArrayBuffer`, other `ArrayBufferView`.

## Files, Streams, and I/O

### `Bun.file` and `Bun.write`

```ts
const file = Bun.file("./data.json");
await file.json();
await file.text();
await file.arrayBuffer();
await file.bytes(); // Uint8Array
file.size; // bytes
file.type; // MIME type
file.lastModified;
await file.exists();
const reader = file.stream(); // ReadableStream

await Bun.write("./out.txt", "hello");
await Bun.write("./out.json", { a: 1 }); // auto JSON.stringify
await Bun.write("./out.bin", someArrayBuffer);
await Bun.write(Bun.stdout, "to stdout");
await Bun.write("./dest.txt", Bun.file("./src.txt")); // copy
```

Incremental writes with `Bun.file().writer()`:

```ts
const writer = Bun.file("./log.txt").writer();
writer.write("first line\n");
writer.write("second line\n");
await writer.flush();
await writer.end();
```

### `Bun.Glob`

```ts
import { Glob } from "bun";

const glob = new Glob("**/*.ts");
for await (const path of glob.scan({ cwd: "./src", onlyFiles: true })) {
  console.log(path);
}
glob.match("src/foo.ts"); // boolean
```

Options: `dot`, `absolute`, `onlyFiles`, `followSymlinks`, `throwErrorOnBrokenSymlink`.

### `Bun.mmap`

Memory-map a file into a Uint8Array. Zero-copy reads for very large files.

```ts
const buf = Bun.mmap("./huge.bin");
console.log(buf.byteLength);
```

### `Bun.indexOfLine`

Fast line-start scan. For tailing logs or parsing line-oriented files without full `split`.

```ts
const idx = Bun.indexOfLine(buffer, 0); // returns offset of first newline
```

### `Bun.fileURLToPath` / `Bun.pathToFileURL`

```ts
Bun.fileURLToPath(new URL("file:///C:/path/to/file.ts"));
Bun.pathToFileURL("/path/to/file.ts");
```

Cross-platform URL-to-path conversion. Replaces `node:url` boilerplate.

## Process and Subprocess

### `Bun.spawn` and `Bun.spawnSync`

`$` shell is great for one-liners. For long-running processes, IPC, or raw stdin/stdout streaming, use `Bun.spawn`.

```ts
const proc = Bun.spawn(["git", "status", "--porcelain"], {
  stdout: "pipe",
  stderr: "pipe",
  cwd: "./repo",
  env: { ...process.env, LANG: "C" },
});

const output = await new Response(proc.stdout).text();
await proc.exited;
proc.exitCode;
```

With IPC (parent-child JSON message passing):

```ts
const child = Bun.spawn(["bun", "./worker.ts"], {
  ipc(message, subprocess) {
    console.log("from worker:", message);
  },
});
child.send({ task: "work" });
```

Synchronous variant:

```ts
const { stdout, exitCode } = Bun.spawnSync(["echo", "hello"]);
```

**Env inheritance.** `{ ...process.env, ... }` hands every secret in the parent process to the child, including AWS creds, OAuth tokens, signing keys. When spawning third-party binaries or commands derived from user input, pass an explicit allowlist:

```ts
const safeEnv = { PATH: process.env.PATH, HOME: process.env.HOME, LANG: "C" };
Bun.spawn(cmd, { env: safeEnv });
```

### `Bun.which`

```ts
Bun.which("git"); // "/usr/bin/git" or null
Bun.which("git", { PATH: process.env.PATH });
```

Cross-platform executable lookup. Replaces `which` npm package.

### `process.execve()`

POSIX-only process replacement matching Node.js v24. It replaces the current process image and never returns on success.

```ts
process.execve("/usr/bin/echo", ["echo", "hello"], {
  PATH: process.env.PATH,
});
```

It inherits stdio, resets the signal mask, throws from workers, throws on Windows, and emits an experimental warning once per process. Use for niche wrapper/launcher CLIs, not normal subprocess execution.

### `Bun.$` (shell)

See `references/cli-backend.md` for full coverage. Quick reference:

```ts
import { $ } from "bun";

await $`ls -la`;
const text = await $`echo hello`.text();
const json = await $`cat package.json`.json();
const { exitCode } = await $`may-fail`.nothrow().quiet();
await $`cmd`.cwd("./sub").env({ FOO: "bar" });
```

## Networking

### Experimental HTTP/2 and HTTP/3 `fetch()`

`fetch()` supports opt-in HTTP/2 and HTTP/3 clients in v1.3.14. These are experimental.

```ts
await fetch("https://example.com", { protocol: "http2" });
await fetch("https://example.com", { protocol: "http3" });
```

Accepted protocol aliases: `"http2"`, `"h2"`, `"http1.1"`, `"h1"`, `"http3"`, `"h3"`. HTTP/2 can also be enabled globally with `--experimental-http2-fetch` or `BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP2_CLIENT=1`. HTTP/3 Alt-Svc upgrades can be enabled with `--experimental-http3-fetch` or `BUN_FEATURE_FLAG_EXPERIMENTAL_HTTP3_CLIENT=1`.

Do not make these the default production recommendation yet.

### TCP sockets: `Bun.listen` and `Bun.connect`

```ts
const server = Bun.listen({
  hostname: "0.0.0.0",
  port: 7000,
  socket: {
    open(socket) {
      socket.write("hello\n");
    },
    data(socket, data) {
      socket.write(data);
    },
    close(socket) {},
    error(socket, error) {},
  },
});

const client = await Bun.connect({
  hostname: "localhost",
  port: 7000,
  socket: {
    data(s, d) {
      /* ... */
    },
    open(s) {
      s.write("ping");
    },
  },
});
```

Use for database drivers, game servers, custom protocols. Much faster than `node:net` in Bun's benchmarks.

### UDP: `Bun.udpSocket`

```ts
const socket = await Bun.udpSocket({
  port: 9000,
  socket: {
    data(socket, buf, port, addr) {
      /* ... */
    },
  },
});
socket.send("ping", 9001, "127.0.0.1");
```

Voice chat, telemetry, DNS, WireGuard-style protocols.

### `Bun.dns`

```ts
await Bun.dns.lookup("bun.sh");
await Bun.dns.lookup("bun.sh", { family: 6 });
await Bun.dns.prefetch("api.example.com"); // warm DNS cache
Bun.dns.getCacheStats();
```

`Bun.dns.prefetch` is especially valuable before the first `fetch()` to a new host.

## HTTP Server

Covered in `cli-backend.md` and SKILL.md. Quick reminders of less-obvious v1.3 features:

### `request.cookies`

```ts
Bun.serve({
  fetch(req) {
    const session = req.cookies.get("session");
    req.cookies.set("last-seen", new Date().toISOString(), {
      httpOnly: true,
      secure: true,
      sameSite: "strict",
      maxAge: 86400,
    });
    return new Response("ok");
  },
});
```

Set-Cookie headers are emitted automatically. Zero overhead when not used.

### Cluster servers with `reusePort`

```ts
Bun.serve({ port: 3000, reusePort: true, fetch: handler });
```

Run the same server in multiple processes; the kernel load-balances. Classic `cluster` pattern without the module.

### Built-in metrics

```ts
Bun.serve({
  port: 3000,
  fetch: handler,
  // internal metrics collected automatically; see Bun.serve docs
});
```

### TLS

```ts
Bun.serve({
  port: 443,
  tls: {
    key: Bun.file("./key.pem"),
    cert: Bun.file("./cert.pem"),
    ca: Bun.file("./ca.pem"), // mTLS
  },
  fetch: handler,
});
```

### Experimental HTTP/3 server

`Bun.serve()` can listen for HTTP/3 over QUIC when TLS is configured:

```ts
Bun.serve({
  port: 443,
  tls: { key: Bun.file("./key.pem"), cert: Bun.file("./cert.pem") },
  http3: true,
  fetch() {
    return new Response("ok");
  },
});
```

This binds TCP for HTTP/1.1+2 and UDP for HTTP/3 on the same port. It is highly experimental. No WebSocket over HTTP/3, no 0-RTT, no trailers, and no HTTP/1.1-style `Expect: 100-continue` support.

### `Bun.FileSystemRouter`

Next.js-style file-system routing as a standalone API.

```ts
const router = new Bun.FileSystemRouter({
  style: "nextjs",
  dir: "./pages",
});
const match = router.match("/blog/hello");
// { filePath, params, query, ... }
```

Wire into `Bun.serve()` for custom frameworks.

## Cron

### `Bun.cron`

Three forms: in-process scheduler, OS-level job registration, and expression parsing. All use standard 5-field cron syntax plus nicknames (`@daily`, `@hourly`, `@weekly`, `@monthly`, `@yearly`).

**In-process scheduler.** Runs a callback inside the current process. Schedules in UTC.

```ts
const job = Bun.cron("*/5 * * * *", async () => {
  await syncToDatabase();
});

// CronJob handle.
job.stop(); // cancel
job.unref(); // allow process to exit while scheduled
job.ref(); // keep process alive (default)
job.cron; // the schedule string

// Disposable - auto-stops at scope exit.
using j = Bun.cron("@hourly", () => rollupLogs());
```

No-overlap guarantee: the next fire is computed after the current handler's Promise settles. Invocations never stack. Errors route to `uncaughtException` / `unhandledRejection`.

**OS-level job** (survives reboots). Registers with `crontab` / `launchd` / Task Scheduler. Schedules in the system local time zone.

```ts
await Bun.cron("./worker.ts", "30 2 * * MON", "weekly-report");
await Bun.cron.remove("weekly-report");
```

The script must export a default object with `scheduled(controller)` (Cloudflare Workers shape):

```ts
// worker.ts
export default {
  async scheduled(controller: Bun.CronController) {
    controller.cron; // the expression
    controller.scheduledTime; // Date.now() at invocation
    await doWork();
  },
};
```

**Parse expressions.** Returns the next matching UTC `Date`, or `null`.

```ts
const next = Bun.cron.parse("@daily");
const after = Bun.cron.parse("*/15 * * * *", next); // chain for N upcoming times
```

Windows has a 48-trigger limit on Task Scheduler for OS-level jobs, so some expressions valid on Linux/macOS (e.g. `*/7 * * * *`) will throw on Windows. Stick to divisors of 60 (`*/1, */2, */3, */4, */5, */6, */10, */12, */15, */20, */30`) for portability.

## Browser Automation

### `Bun.WebView` (experimental)

Headless browser controlled from Bun. On macOS uses the system `WKWebView` (zero dependencies); on Linux and Windows drives an installed Chrome/Chromium/Edge/Brave over Chrome DevTools Protocol. Each view runs in its own renderer process; native input events (`isTrusted: true`).

```ts
await using view = new Bun.WebView({ width: 1280, height: 720 });
await view.navigate("https://example.com");
const title = await view.evaluate("document.title");
await Bun.write("page.png", await view.screenshot());
```

**Evaluating JavaScript in the page.** `evaluate()` runs in the page's JavaScript context with full DOM access and whatever cookies/auth the page holds. Treat its argument as code, not data.

```ts
// SAFE: static expression, no untrusted data.
const items = await view.evaluate(
  "[...document.querySelectorAll('li')].map(li => li.textContent)",
);

// UNSAFE: string concat with user input is JS injection in the page context.
// await view.evaluate(`document.querySelector('${userSelector}').innerText`);

// SAFER: JSON-serialize every interpolated value so it embeds as a JS literal.
const safeSelector = JSON.stringify(userSelector);
await view.evaluate(`document.querySelector(${safeSelector})?.innerText`);
```

Constructor options: `width`, `height`, `url`, `backend` (`"webkit"` default on macOS; `"chrome"` elsewhere), `dataStore` (`"ephemeral"` or `{ directory }` for persistent storage), `console` (mirror page `console.*` to `globalThis.console` or a custom handler).

**Persistence and privacy.** Default to `"ephemeral"`. A persistent `dataStore.directory` holds cookies, LocalStorage, IndexedDB, and cache for every origin the view has visited; treat it as sensitive. Add the directory to `.gitignore`, restrict file permissions, rotate by deleting it.

**Interaction.** All input dispatches native browser events; the page sees `isTrusted: true`.

```ts
// Click by coordinates or CSS selector (waits for element to be actionable).
await view.click(150, 200);
await view.click("#submit", { timeout: 5000 });
await view.click("button", { button: "right", modifiers: ["Shift"] });

// Typing (uses InsertText, no per-char keystrokes).
await view.click("input#email");
await view.type("hello@example.com");

// Named keys.
await view.press("Enter");
await view.press("a", { modifiers: ["Meta"] }); // Cmd+A / Ctrl+A

// Scroll.
await view.scroll(0, 500); // wheel event at center
await view.scrollTo("#footer", { block: "center" }); // scroll element into view
await view.resize(1920, 1080);
```

**Navigation.**

```ts
await view.navigate("https://example.com");
await view.goBack();
await view.goForward();
await view.reload();

view.onNavigated = (url, title) => {
  /* ... */
};
view.onNavigationFailed = (err) => {
  /* ... */
};
view.url; // current URL
view.title; // page title
view.loading; // navigation in flight
```

**Screenshots.**

```ts
const png = await view.screenshot(); // Blob
const jpeg = await view.screenshot({ format: "jpeg", quality: 90 });
const buf = await view.screenshot({ encoding: "buffer" }); // Buffer
const b64 = await view.screenshot({ encoding: "base64" }); // string
```

**Raw Chrome DevTools Protocol** (Chrome backend only).

```ts
await view.cdp("Network.enable");
view.addEventListener("Network.responseReceived", (event) => {
  console.log(event.data.response.status, event.data.response.url);
});
await view.cdp("Emulation.setUserAgentOverride", { userAgent: "MyBot/1.0" });
```

**Lifecycle.**

```ts
view.close(); // synchronous, idempotent
Bun.WebView.closeAll(); // force-kill all browser subprocesses
```

Concurrency model: one operation of each kind in flight at a time per view (one `navigate()`, one `evaluate()`, one `screenshot()`, one `click/type/press/scroll`, one `cdp()`). Concurrent calls throw synchronously - just `await` each call. Different views run fully parallel.

**Finding Chrome on Linux/Windows.** Searches `BUN_CHROME_PATH`, `$PATH`, standard install locations, and Playwright's cache. Override with `backend: { type: "chrome", path: "/path/to/chrome" }` or connect to a running Chrome via `backend: { type: "chrome", url: "ws://..." }`.

Use cases: screenshot/PDF generation, OG image rendering, scraping JS-heavy pages, end-to-end testing. Meaningfully lighter than Playwright/Puppeteer for simple flows; drop to raw CDP when you need more.

## Compression

### zstd (v1.3)

```ts
import {
  zstdCompress,
  zstdDecompress,
  zstdCompressSync,
  zstdDecompressSync,
} from "bun";

const compressed = await zstdCompress("hello world");
const text = new TextDecoder().decode(await zstdDecompress(compressed));

const syncOut = zstdCompressSync(Buffer.from("data"));
```

### gzip, deflate

```ts
Bun.gzipSync(buffer);
Bun.gunzipSync(buffer);
Bun.deflateSync(buffer);
Bun.inflateSync(buffer);
```

`fetch()` automatically decompresses zstd, br, and gzip responses.

## Concurrency Primitives

### Workers

```ts
const worker = new Worker(new URL("./worker.ts", import.meta.url).href);
worker.postMessage({ task: "hash", input: "hello" });
worker.onmessage = (e) => console.log(e.data);
```

Workers run on a separate JS thread. Share I/O resources with the main thread. Work in compiled executables.

### `DisposableStack` and `AsyncDisposableStack`

From the TC39 Explicit Resource Management proposal.

```ts
{
  using stack = new DisposableStack();
  const db = stack.use(new Database(":memory:"));
  const server = stack.use({
    [Symbol.dispose]() {
      /* stop server */
    },
  });
  // resources disposed in reverse order when the scope ends
}
```

Async variant:

```ts
await using stack = new AsyncDisposableStack();
stack.use({
  async [Symbol.asyncDispose]() {
    await cleanup();
  },
});
```

Pairs well with `Bun.sql` connections, `Bun.spawn` processes, temp files, and any `using`-capable API.

## FFI and Native Code

`dlopen()` loads a shared library into the Bun process; `cc` compiles and loads inline C. Both run with full process privileges; there is no sandbox. Never pass user-controlled paths to `dlopen()`, and never embed user-controlled strings into `cc` source. Treat these APIs like `eval`.

### `bun:ffi` — call native libraries

```ts
import { dlopen, FFIType, ptr, CString } from "bun:ffi";

const lib = dlopen("libmath.so", {
  add: {
    args: [FFIType.i32, FFIType.i32],
    returns: FFIType.i32,
  },
});
lib.symbols.add(2, 3);
```

### `cc` — inline C compiler

Compile and call C without a build step.

```ts
import { cc } from "bun:ffi";

const { symbols } = cc({
  source: `
    int add(int a, int b) { return a + b; }
  `,
  symbols: {
    add: { args: ["int", "int"], returns: "int" },
  },
});
symbols.add(1, 2);
```

Useful for SIMD hot paths, wrapping existing C libraries, or calling syscalls that Bun does not expose.

## Utilities

### Deep equality and matching

```ts
Bun.deepEquals({ a: 1, b: [2, 3] }, { a: 1, b: [2, 3] }); // strict deep equality

// deepMatch(subset, superset) - true if every key/value in subset appears in superset.
Bun.deepMatch({ id: "abc" }, { id: "abc", name: "Alice", extra: 42 }); // true
Bun.deepMatch({ id: "abc", missing: 1 }, { id: "abc" }); // false
```

`deepEquals` requires strict equality. `deepMatch` is asymmetric: the first argument is the pattern, the second is the object under test; extra keys in the second argument are ignored. Same algorithm that powers `expect().toMatchObject()` in `bun:test`. Safe to use outside tests.

### HTML escaping

```ts
Bun.escapeHTML("<script>alert(1)</script>");
```

### Time utilities

```ts
Bun.sleep(1000); // returns a Promise
Bun.sleepSync(1000); // blocks
Bun.nanoseconds(); // monotonic nanosecond timer
```

### Semver

```ts
import { semver } from "bun";

semver.satisfies("1.2.3", "^1.0.0");
semver.order("1.2.3", "1.10.0"); // -1, 0, or 1
```

### `Bun.plugin` (programmatic plugin registration)

```ts
Bun.plugin({
  name: "my-plugin",
  setup(build) {
    build.onLoad({ filter: /\.txt$/ }, async (args) => ({
      contents: `export default ${JSON.stringify(await Bun.file(args.path).text())}`,
      loader: "js",
    }));
  },
});
```

For dev scripts and test setup. For production builds, use `Bun.build({ plugins })` or `bunfig.toml`.

### `Bun.Transpiler`

Programmatic TS/JSX transpile without bundling.

```ts
const t = new Bun.Transpiler({ loader: "tsx" });
t.transformSync("const x: number = 1;");
t.scan("import { a } from 'b';"); // discover imports/exports
```

## Memory and Diagnostics

### `bun:jsc`

```ts
import {
  memoryUsage,
  heapStats,
  heapSize,
  estimateShallowMemoryUsageOf,
  generateHeapSnapshotForDebugging,
  percentAvailableMemoryInUse,
} from "bun:jsc";

memoryUsage(); // detailed JSC memory stats
heapStats(); // object counts by type
heapSize(); // live heap size in bytes
estimateShallowMemoryUsageOf(obj); // per-object estimate
percentAvailableMemoryInUse(); // 0.0 to 1.0
```

More detailed than `process.memoryUsage()`. Use when profiling or implementing memory-aware caches.

### `Bun.generateHeapSnapshot`

```ts
const snapshot = Bun.generateHeapSnapshot();
await Bun.write("./heap.heapsnapshot", JSON.stringify(snapshot));
```

Open the `.heapsnapshot` file in Chrome DevTools > Memory.

### `Bun.gc` and `Bun.shrink`

```ts
Bun.gc(true); // force full GC (sync)
Bun.gc(false); // async
Bun.shrink(); // release idle memory to the OS
```

Use in long-running daemons after large allocations.

## Environment

### Auto-loaded `.env`

Bun loads in priority order:

1. `.env.{NODE_ENV}.local`
2. `.env.local` (except for test environment)
3. `.env.{NODE_ENV}`
4. `.env`

Access via `process.env` or `Bun.env`. Disable by setting `env = false` in `bunfig.toml`.

### Deployment hardening

- Add `.env*` to `.gitignore` and `.dockerignore`. `COPY . .` in Dockerfiles routinely ships stray developer `.env.local` files into images.
- In production, pass secrets via the orchestrator (Kubernetes secrets, Docker secrets, a vault) and set `env = false` in `bunfig.toml` so the runtime does not silently load a misplaced file.
- `.env.local` overrides `.env`, so anyone with write access to the working directory can redirect `DATABASE_URL` to a capture host. Keep working directories restrictive.

### `--env-file` override

```bash
bun --env-file=.env.production server.ts
```

When a CLI accepts `--env-file` from user input, resolve the path, verify it sits under an allowlisted directory, and reject symlinks. Pointing a privileged process at an attacker-controlled file becomes credential injection.

### Build-time inlining

```ts
await Bun.build({
  entrypoints: ["./app.ts"],
  env: "PUBLIC_*", // inline env vars matching prefix
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
});
```

## Import Attributes (Type Hints)

```ts
import config from "./config.yaml"; // auto-detected
import raw from "./data.txt" with { type: "text" };
import bytes from "./logo.png" with { type: "file" }; // path string
import db from "./seed.db" with { type: "sqlite", embed: "true" };
import data from "./data.json" with { type: "json" };
import wasm from "./m.wasm"; // auto
```

Embed-type imports bundle the asset into compiled executables.

## `import.meta`

| Property                    | Value                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------- |
| `import.meta.path`          | Absolute path to the current file.                                                      |
| `import.meta.file`          | Basename.                                                                               |
| `import.meta.dir`           | Directory.                                                                              |
| `import.meta.url`           | `file://` URL.                                                                          |
| `import.meta.main`          | `true` if this file is the entrypoint. Equivalent to Python's `__name__ == "__main__"`. |
| `import.meta.env`           | Not supported in Bun. Use `process.env` or the build `env` option.                      |
| `import.meta.hot`           | HMR API in dev server. See SKILL.md.                                                    |
| `import.meta.resolve(spec)` | Resolve a specifier to an absolute URL.                                                 |
| `import.meta.require(spec)` | Sync require inside ESM modules.                                                        |

## Globals Bun Adds

- `Bun` - everything above.
- `HTMLRewriter` - streaming HTML transform using CSS selectors.
- `fetch`, `Request`, `Response`, `Headers`, `FormData`, `URL`, `URLSearchParams`.
- `WebSocket`, `CloseEvent`, `MessageEvent`.
- `ReadableStream`, `WritableStream`, `TransformStream`.
- `Blob`, `File`.
- `DisposableStack`, `AsyncDisposableStack`.
- `crypto` (Web Crypto).
- `performance`, `structuredClone`, `queueMicrotask`.
- `setImmediate`, `clearImmediate` (via `node:timers`).

## Globals Bun Does NOT Add

- `import.meta.env` (Vite-specific; use `process.env`).
- `import.meta.glob` (Vite-specific).
- `require.resolve` inside ESM (use `import.meta.resolve`).

## Node.js Compatibility

Most of `node:*` modules work in Bun. Hot paths often have Bun-native equivalents that are 2-10x faster.

| Prefer             | Over                           |
| ------------------ | ------------------------------ |
| `Bun.file()`       | `fs.readFile` / `fs.writeFile` |
| `Bun.serve`        | `http.createServer`            |
| `Bun.sql`          | `pg`, `mysql2`                 |
| `Bun.$`            | `child_process`                |
| `Bun.Glob`         | `glob`, `fast-glob`            |
| `Bun.CryptoHasher` | `crypto.createHash`            |

Where Node ergonomics are better (e.g. `node:path`, `node:fs/promises` for non-hot code, `node:util.parseArgs`), use them directly. No reason to avoid `node:*` modules; they are first-class in Bun.

v1.3.14 improved enterprise TLS and memory behavior: TLS-using APIs share SSL context cache entries, `tls.getCACertificates("system")` works without `--use-system-ca`, macOS system CA enumeration avoids network stalls, and Windows `--use-system-ca` reads intermediate and TrustedPeople stores. Keep the existing trust model in mind: using system CAs intentionally trusts local enterprise roots and TLS-inspection proxies.

## Quick Probe

To verify any API on your Bun install:

```bash
bun -e 'console.log(typeof Bun.cron, typeof Bun.WebView, typeof Bun.secrets)'
```

Returns `"function"` or `"object"` when available, `"undefined"` otherwise.
