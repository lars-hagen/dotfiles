# Zig Standard Library Cheatsheet (0.16)

Common std APIs, verified against the bundled 0.16.0 std source (`zig env` -> `<lib_dir>/std/`). Organized by task.

## Allocators

```zig
// In main: init.gpa and init.arena.allocator() are always available.
const arena = init.arena.allocator();
const gpa = init.gpa;

// Standalone arena:
var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena_state.deinit();
const a = arena_state.allocator();

// Standalone DebugAllocator (leak checker):
var dbg: std.heap.DebugAllocator(.{}) = .init;
defer if (dbg.deinit() == .leak) @panic("leaked memory");
const gpa2 = dbg.allocator();

// FixedBufferAllocator (no heap, never fails):
var buf: [4096]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buf);
const fa = fba.allocator();

// Fast SMP allocator for release builds:
const smp = std.heap.smp_allocator;
_ = smp;

// libc malloc (requires `.link_libc = true` on the module):
const c_alloc = std.heap.c_allocator;
_ = c_alloc;
```

## Collections

### ArrayList (unmanaged by default)

```zig
var list: std.ArrayList(u32) = .empty;
defer list.deinit(gpa);

try list.append(gpa, 1);
try list.append(gpa, 2);
try list.appendSlice(gpa, &.{ 3, 4, 5 });

for (list.items) |x| _ = x;

try list.insert(gpa, 0, 0);
_ = list.pop();      // returns last or panics
_ = list.swapRemove(0);

// Managed form, if you really want the allocator embedded.
// Note: std.ArrayList is a function, not a namespace. The managed wrapper
// lives at std.array_list.Managed(T).
var mlist: std.array_list.Managed(u32) = .init(gpa);
defer mlist.deinit();
try mlist.append(42);
```

### HashMap

```zig
// StringHashMap(V) keys by []const u8.
var map: std.StringHashMap(u32) = .init(gpa);
defer map.deinit();
try map.put("one", 1);
if (map.get("one")) |v| _ = v;
_ = map.remove("one");

// AutoHashMap for primitive/enum keys.
var m2: std.AutoHashMap(u64, []const u8) = .init(gpa);
defer m2.deinit();
try m2.put(1, "hello");

// Ordered/array-backed (maintains insertion order). Only the unmanaged
// form is exposed at std top level; pass gpa to each method.
var m3: std.StringArrayHashMapUnmanaged(u32) = .empty;
defer m3.deinit(gpa);
```

### BufMap / BufSet

Owning versions of `StringHashMap([]const u8)` and `StringHashMap(void)`, convenient for CLI arg storage:

```zig
var env = std.BufMap.init(gpa);
defer env.deinit();
try env.put("FOO", "bar");  // copies key and value into the map
```

## Strings and Formatting

```zig
// Format to allocator:
const s = try std.fmt.allocPrint(gpa, "x = {d}", .{42});
defer gpa.free(s);

// Format into a fixed buffer:
var buf: [128]u8 = undefined;
const out = try std.fmt.bufPrint(&buf, "x = {d}", .{42});
_ = out;

// Parse:
const n = try std.fmt.parseInt(u32, "42", 10);
const f = try std.fmt.parseFloat(f64, "3.14");
_ = n;
_ = f;

// Hex:
const bytes = [_]u8{ 0xde, 0xad };
var buf2: [64]u8 = undefined;
const hex = try std.fmt.bufPrint(&buf2, "{x}", .{&bytes});  // "dead"
_ = hex;
```

### `std.mem`

```zig
std.mem.eql(u8, "a", "b");              // slice equality
std.mem.indexOf(u8, "hello", "ll");     // ?usize
std.mem.startsWith(u8, "foo.txt", "foo");
std.mem.endsWith(u8, "foo.txt", ".txt");
std.mem.trim(u8, "  x  ", " ");
std.mem.tokenizeScalar(u8, "a,b,c", ',');   // iterator, skips empty
std.mem.splitScalar(u8, "a,,b", ',');       // iterator, keeps empty
std.mem.concat(gpa, u8, &.{ "foo", "bar" });
std.mem.join(gpa, "/", &.{ "a", "b", "c" });
std.mem.span(cstring);  // [*:0]const u8 -> []const u8
```

## Stdio

```zig
const Io = std.Io;

// Unbuffered stderr, always safe:
std.debug.print("debug: {s}\n", .{"hello"});

// Buffered stdout:
var buf: [4096]u8 = undefined;
var fw: Io.File.Writer = .init(.stdout(), init.io, &buf);
const out = &fw.interface;
try out.print("result = {d}\n", .{42});
try out.flush();

// Buffered stdin:
var in_buf: [4096]u8 = undefined;
var fr: Io.File.Reader = .init(.stdin(), init.io, &in_buf);
const in = &fr.interface;

// Read a line (without the trailing '\n'). EOF is treated as a delimiter:
// the final unterminated line is returned; a subsequent call with no bytes
// left yields error.EndOfStream.
while (in.takeDelimiterExclusive('\n')) |line| {
    std.debug.print("got: {s}\n", .{line});
} else |err| switch (err) {
    error.EndOfStream => {},
    else => return err,
}
```

Flush writers before `std.process.exit` or the last bytes may be lost.

## JSON

```zig
const std = @import("std");

// Parse into a typed struct:
const Config = struct {
    name: []const u8,
    port: u16,
    tags: []const []const u8,
};

const text =
    \\{"name":"api","port":8080,"tags":["a","b"]}
;

const parsed = try std.json.parseFromSlice(Config, gpa, text, .{});
defer parsed.deinit();
const cfg: Config = parsed.value;
_ = cfg;

// Parse into a dynamic Value:
const dyn = try std.json.parseFromSlice(std.json.Value, gpa, text, .{});
defer dyn.deinit();
switch (dyn.value) {
    .object => |o| _ = o,
    else => {},
}

// Stringify. Signature: Stringify.value(value, options, writer) -- note the
// argument order; the writer is last.
var list: std.ArrayList(u8) = .empty;
defer list.deinit(gpa);
var aw: std.Io.Writer.Allocating = .fromArrayList(gpa, &list);
try std.json.Stringify.value(.{ .name = "api", .port = 8080 }, .{}, &aw.writer);
// aw.writer's output now lives in list.items.

// For small cases, allocPrint-style is simpler:
const s = try std.json.Stringify.valueAlloc(gpa, .{ .name = "api", .port = 8080 }, .{});
defer gpa.free(s);
```

## Files and Directories

`std.Io.Dir` and `std.Io.File` replace the old `std.fs` API surface.

```zig
const io = init.io;

// Open cwd:
var cwd = std.Io.Dir.cwd();

// Read entire file (Io.Limit is a capped-read budget; use .unlimited with care):
const contents = try cwd.readFileAlloc(io, "data.txt", gpa, .limited(1_000_000));
defer gpa.free(contents);

// Write file:
try cwd.writeFile(io, .{ .sub_path = "out.txt", .data = "hello" });

// Create file, open file:
var f = try cwd.createFile(io, "log.txt", .{});
defer f.close(io);

// Iterate dir entries (recursive walker):
var dir = try cwd.openDir(io, "src", .{ .iterate = true });
defer dir.close(io);
var walker = try dir.walk(gpa);
defer walker.deinit();
while (try walker.next(io)) |entry| {
    std.debug.print("{s}\n", .{entry.path});
}
```

The `std.fs` namespace is still present for path helpers and platform-specific primitives; most high-level file and directory operations in 0.16 live under `std.Io.Dir` / `std.Io.File` and take an `Io` parameter.

## Subprocess

```zig
// One-shot: run and capture output.
const res = try std.process.run(gpa, init.io, .{
    .argv = &.{ "git", "rev-parse", "HEAD" },
});
defer gpa.free(res.stdout);
defer gpa.free(res.stderr);
const sha = std.mem.trim(u8, res.stdout, "\n\r ");
_ = sha;

// Lower-level: spawn and interact. Note std.process.spawn, not Child.init.
// SpawnOptions fields: argv, stdin/stdout/stderr (StdIo union: .inherit,
// .pipe, .ignore, .close, .{ .file = f }), cwd, environ_map, ...
var child = try std.process.spawn(init.io, .{
    .argv = &.{ "grep", "foo" },
    .stdin = .pipe,
    .stdout = .pipe,
});
_ = try child.wait(init.io);
// child.stdin / child.stdout are std.Io.File values when .pipe was requested.
// Use init.io-based writers/readers on them.
```

## Hashing and Crypto

```zig
const crypto = std.crypto;

// SHA-256:
var sha = crypto.hash.sha2.Sha256.init(.{});
sha.update("hello ");
sha.update("world");
var digest: [32]u8 = undefined;
sha.final(&digest);

// One-shot:
var digest2: [32]u8 = undefined;
crypto.hash.sha2.Sha256.hash("hello world", &digest2, .{});

// Blake3:
var digest3: [32]u8 = undefined;
crypto.hash.Blake3.hash("hi", &digest3, .{});

// HMAC-SHA256:
var mac: [32]u8 = undefined;
crypto.auth.hmac.sha2.HmacSha256.create(&mac, "message", "key");

// AEAD (ChaCha20-Poly1305):
const Aead = crypto.aead.chacha_poly.ChaCha20Poly1305;
var ciphertext: [64]u8 = undefined;
var tag: [Aead.tag_length]u8 = undefined;
const key: [Aead.key_length]u8 = undefined;
const nonce: [Aead.nonce_length]u8 = undefined;
Aead.encrypt(ciphertext[0.."hello world".len], &tag, "hello world", "", nonce, key);
```

## Random

```zig
// Non-crypto PRNG:
var prng = std.Random.DefaultPrng.init(0xc0ffee);
const r = prng.random();
const n = r.int(u32);
const x = r.float(f64);
const y = r.intRangeAtMost(u8, 1, 6);  // inclusive 1..=6
_ = .{ n, x, y };

// Seeded from OS entropy. The 0.16 way is std.Random.IoSource, which wraps
// the Io abstraction's CSPRNG-quality entropy source.
var entropy: std.Random.IoSource = .{ .io = init.io };
const random = entropy.interface();
const seed: u64 = random.int(u64);
var prng2 = std.Random.DefaultPrng.init(seed);
_ = &prng2;

// IoSource also serves as a CSPRNG-quality source directly when you do
// not need a deterministic PRNG seeded from it:
_ = random.int(u64);
```

`std.crypto.random` from earlier releases is gone; route through `std.Random.IoSource{ .io = io }.interface()` instead.

## Time

In 0.16, `std.time` only exposes constants (`ns_per_s`, `ns_per_ms`, etc.).
Wall-clock and monotonic timestamps moved to the `Io.Clock` API; sleeping
moved to `io.sleep` / `Clock.Duration.sleep`.

```zig
// Monotonic timestamp via the Io abstraction. The 0.16 monotonic clock is
// named `.awake` (it explicitly excludes time the system was suspended);
// `.boot` is the version that includes suspended time, `.real` is wall clock.
const t0 = std.Io.Clock.now(.awake, init.io);
// ... work ...
const t1 = std.Io.Clock.now(.awake, init.io);
const elapsed = t0.durationTo(t1); // Io.Duration

// Sleep:
try init.io.sleep(.fromSeconds(1), .awake);
try init.io.sleep(.fromMilliseconds(500), .awake);
```

The legacy `std.time.nanoTimestamp`, `std.time.milliTimestamp`, and
`std.Thread.sleep` from earlier releases are gone.

## Threads and Atomics

```zig
// Spawn:
fn worker(arg: u32) void {
    std.debug.print("arg = {d}\n", .{arg});
}
var t = try std.Thread.spawn(.{}, worker, .{42});
t.join();

// Mutex:
var m: std.Thread.Mutex = .{};
m.lock();
defer m.unlock();

// Atomic value:
var counter: std.atomic.Value(u32) = std.atomic.Value(u32).init(0);
_ = counter.fetchAdd(1, .seq_cst);
const v = counter.load(.seq_cst);
_ = v;
```

## Compression

```zig
// Gzip decompress. std.compress.flate exposes Compress, Decompress, and
// a Container enum (.raw, .zlib, .gzip). There is no flate.gzip submodule.
// The exact Decompress init API shifts fast; consult
// std.compress.flate.Decompress in the on-disk std for the current shape:
//   <lib_dir>/std/compress/flate/Decompress.zig  (run `zig env` for lib_dir)
// Typical usage: construct a Decompress configured with .gzip container,
// feed it a reader, pump the output to a writer.
```

For zstd there is `std.compress.zstd`; for xz there is `std.compress.xz`. Each ships its own streaming and one-shot entry points. Check the on-disk source before copying examples; these APIs churn between releases.

## HTTP Client

```zig
var client: std.http.Client = .{ .allocator = gpa, .io = init.io };
defer client.deinit();

// 0.16 streams responses to a response_writer you provide. Easiest: an
// Allocating writer that captures into an ArrayList.
var body: std.ArrayList(u8) = .empty;
defer body.deinit(gpa);
var aw: std.Io.Writer.Allocating = .fromArrayList(gpa, &body);

const res = try client.fetch(.{
    .location = .{ .url = "https://example.com/" },
    .response_writer = &aw.writer,
});
_ = res.status;
// body.items now contains the response body.
```

The `FetchOptions` field is `response_writer: ?*std.Io.Writer`, not `response_storage`. If you do not set it, `fetch` will panic on a non-empty body.

## Unicode

```zig
// UTF-16 literal (for Win32):
const W = std.unicode.utf8ToUtf16LeStringLiteral;
const wide = W("hello");
_ = wide;

// UTF-8 validation:
const ok = std.unicode.utf8ValidateSlice("hello");
_ = ok;

// Iterate UTF-8 code points:
var it = (try std.unicode.Utf8View.init("caf\u{00E9}")).iterator();
while (it.nextCodepoint()) |cp| _ = cp;
```

## Panic / Fatal / Assert

```zig
std.debug.assert(x == 1);            // disabled in release-fast/small
std.debug.panic("bad: {s}", .{why}); // always panics
std.process.fatal("boom: {d}", .{code}); // prints to stderr then exits 1
```

## SemanticVersion

```zig
const v: std.SemanticVersion = try .parse("1.2.3");
_ = v.major;
const required: std.SemanticVersion = .{ .major = 1, .minor = 0, .patch = 0 };
if (v.order(required) == .lt) @panic("too old");
```
