# Zig 0.16 Language and Stdlib Migration Notes

This is the concrete list of what broke between 0.15 and 0.16 for the surfaces an agent most often touches. Every item below is verified against the bundled 0.16.0 std source (`zig env` -> `<lib_dir>/std/`).

## The New `main` Signature

0.16 introduced `std.process.Init`. The idiomatic entrypoint is:

```zig
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    // init.arena is a *std.heap.ArenaAllocator; usable all program long.
    const arena = init.arena.allocator();

    // init.gpa is a general-purpose Allocator (DebugAllocator in Debug).
    const gpa = init.gpa;
    _ = gpa;

    // init.io is a std.Io implementation.
    const io = init.io;

    // init.minimal is a smaller subset (args + env) for people who want fewer
    // guarantees. init.minimal.args is a std.process.Args.
    const args = try init.minimal.args.toSlice(arena);
    _ = args;

    // init.environ_map is a *std.process.Environ.Map; also accessible as a
    // raw block via init.minimal.environ.
    const user = init.environ_map.get("HOME") orelse "";
    _ = user;

    _ = io;
}
```

### Alternative: `Init.Minimal`

If you do not want Zig to pre-allocate an arena and a gpa for you, accept the smaller form:

```zig
pub fn main(m: std.process.Init.Minimal) !void {
    // m.args, m.environ. Bring your own allocator and Io.
}
```

Most code should take `std.process.Init`. Use `Minimal` only for very small tools or tests.

### Legacy `pub fn main() !void`

Still compiles. You just lose the pre-built arena, gpa, Io, env, and args. If you write it yourself, you end up reimplementing what `Init` gives you.

## Allocators

`std.heap.GeneralPurposeAllocator` is **gone**. Replacements:

| Need | Use |
|------|-----|
| Default leak-checking allocator in Debug | `init.gpa` (already a `DebugAllocator`) |
| Explicit leak-checking allocator | `var dbg: std.heap.DebugAllocator(.{}) = .init; defer _ = dbg.deinit(); const gpa = dbg.allocator();` |
| Arena (bulk-free on drop) | `var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator); defer arena.deinit(); const a = arena.allocator();` |
| Fast SMP allocator (release builds) | `std.heap.smp_allocator` |
| Page allocator (rarely direct) | `std.heap.page_allocator` |
| libc malloc | `std.heap.c_allocator` (requires `.link_libc = true`) |
| Fixed buffer (no heap) | `std.heap.FixedBufferAllocator` |

```zig
// Explicit debug allocator, standalone.
var dbg: std.heap.DebugAllocator(.{}) = .init;
defer {
    if (dbg.deinit() == .leak) @panic("memory leaked");
}
const gpa: std.mem.Allocator = dbg.allocator();
```

## Args

`std.process.argsAlloc` and `std.process.argsFree` are **gone**. The replacements live on `std.process.Args`:

```zig
// Simplest: copy into a slice in arena memory.
const args: []const [:0]const u8 = try init.minimal.args.toSlice(arena);

// Iterator form (cross-platform; handles Windows WTF-16 conversion).
var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
defer it.deinit();
_ = it.next(); // skip argv[0]
while (it.next()) |arg| {
    std.log.info("arg = {s}", .{arg});
}
```

On Windows, args are natively WTF-16; the iterator converts to WTF-8. The slice returned by `toSlice` is `[:0]const u8` (NUL-terminated), owned by the passed allocator.

## Environment variables

`std.process.getEnvVarOwned` is **gone at `std.process` top level**. Replacements:

```zig
// Non-owning read from the pre-populated Map.
if (init.environ_map.get("HOME")) |home| {
    // home is []const u8, valid for as long as the Map.
}

// Owning read (allocates a fresh buffer).
const home = try init.minimal.environ.getAlloc(init.gpa, "HOME");
defer init.gpa.free(home);
```

In `build.zig`:

```zig
const home = b.graph.environ_map.get("HOME") orelse
    @panic("HOME not set");
```

## Stdio

`std.io.getStdOut`, `std.io.getStdErr`, `std.io.getStdIn` are **gone**. The 0.16 path is `std.Io.File`:

```zig
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    var buf: [4096]u8 = undefined;
    var fw: Io.File.Writer = .init(.stdout(), init.io, &buf);
    const out = &fw.interface;
    try out.print("hello {s}\n", .{"world"});
    try out.flush();
}
```

Notes:

- `.stdout()`, `.stderr()`, `.stdin()` are methods on `std.Io.File` that return a `File` bound to the OS stdio handle. `init` does not provide them; they are static.
- `Io.File.Writer.init(file, io, buffer)` wraps the file in a buffered writer. Buffer lifetime is the caller's responsibility.
- `writer.interface` is the `std.Io.Writer` the rest of std consumes; functions that take an `*Io.Writer` accept `&fw.interface`.
- For quick stderr writes from CLI help/version or debug output, `std.debug.print(fmt, args)` is still there and writes unbuffered to stderr.

## ArrayList is now unmanaged

This is the single most common breaking change people hit.

```zig
// 0.16 default form:
var list: std.ArrayList(u8) = .empty;
defer list.deinit(gpa);
try list.append(gpa, 'a');
try list.appendSlice(gpa, "bcd");

// Managed form still exists under std.array_list (not std.ArrayList.Managed,
// because std.ArrayList is a function, not a namespace):
var managed: std.array_list.Managed(u8) = .init(gpa);
defer managed.deinit();
try managed.append('a');
```

The same split applies to `std.AutoHashMap`, `std.StringHashMap`, `std.ArrayHashMap`, and friends: unmanaged is the default and methods take `gpa`.

## Random

`std.rand` was renamed to `std.Random`:

```zig
var prng = std.Random.DefaultPrng.init(0xdeadbeef);
const r = prng.random();
const n = r.int(u32);
_ = n;

// CSPRNG
var csprng = std.Random.DefaultCsprng.init([_]u8{0} ** 32);
const cr = csprng.random();
_ = cr.intRangeAtMost(u64, 0, 100);
```

## Calling convention

`callconv(.Stdcall)` and `std.os.windows.WINAPI` are gone. Use `callconv(.winapi)`:

```zig
extern "user32" fn MessageBoxW(
    hwnd: ?*opaque {},
    text: [*:0]const u16,
    caption: [*:0]const u16,
    flags: u32,
) callconv(.winapi) i32;
```

`.winapi` is an alias that resolves to `x86_stdcall` on 32-bit x86 and to the x64 Windows ABI on 64-bit. You do not pick per target manually.

## `std.ChildProcess` is now `std.process.Child`

The old `std.ChildProcess` namespace is gone. In 0.16 the type lives at `std.process.Child` and is constructed via top-level helpers, not an `init` method:

```zig
// Build + run in one call (captures stdout/stderr).
const result = try std.process.run(gpa, io, .{
    .argv = &.{ "git", "status", "--short" },
});
defer gpa.free(result.stdout);
defer gpa.free(result.stderr);

// Lower level: spawn and interact manually.
var child = try std.process.spawn(io, .{
    .argv = &.{ "grep", "foo" },
    .stdin = .pipe,
    .stdout = .pipe,
});
const term = try child.wait(io);
_ = term;
```

There is no `std.process.Child.init(...)`; use `std.process.spawn(io, opts)` (returns `Child`) or `std.process.run(gpa, io, opts)` (one-shot, returns `RunResult`).

## Hex formatting: `{x}` on a slice, not `fmtSliceHexLower`

`std.fmt.fmtSliceHexLower` and `fmtSliceHexUpper` are **gone in 0.16**. The `{x}` format spec now natively handles byte slices:

```zig
const hash = [_]u8{ 0xde, 0xad, 0xbe, 0xef };
try out.print("hash = {x}\n", .{&hash});          // "hash = deadbeef"
try out.print("HASH = {X}\n", .{&hash});          // uppercase
```

For a comptime-known array, there is also `std.fmt.bytesToHex(bytes, .lower)` which returns a `[N*2]u8`:

```zig
const encoded = std.fmt.bytesToHex(hash, .lower);
try out.print("{s}\n", .{&encoded});
```

## Build options on `Module` vs `Compile`

Several options migrated from `*Step.Compile` to `*Build.Module`:

- `linkSystemLibrary`: now on Module.
- `linkLibC` / `linkLibCpp`: removed as methods. Set `.link_libc = true` (or `.link_libcpp = true`) in `Module.CreateOptions`, or call `mod.linkSystemLibrary("c", .{})` (it auto-promotes to libc).
- `addCSourceFile`, `addCSourceFiles`: on Module.
- `addIncludePath`: on Module.
- `strip`: a field on `Module.CreateOptions`.

```zig
const mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .strip = true,
});
mod.linkSystemLibrary("sqlite3", .{});
mod.addIncludePath(b.path("vendor/include"));

const exe = b.addExecutable(.{ .name = "tool", .root_module = mod });
b.installArtifact(exe);
```

## `standardReleaseOptions` removed

Replaced by `standardOptimizeOption`:

```zig
const optimize = b.standardOptimizeOption(.{});
// Optional: what bare `--release` means. Plain `zig build` still defaults to Debug.
const optimize2 = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
_ = optimize2;
```

## `b.default_step` is reassignable

```zig
const sign_step = b.step("sign", "Build and sign");
sign_step.dependOn(&sign_cmd.step);
b.default_step = sign_step; // now bare `zig build` runs sign
```

Do not make `install` depend on `sign_step` while `sign_step` depends on `install`; that is a cycle.

## `@errorFromInt` / `@intFromError` / `@intFromEnum`

These naming changes happened earlier (0.11 era) but tutorials still use the old forms. Quick list:

| Old | New |
|-----|-----|
| `@intCast(T, x)` | `@intCast(x)` with result-location inference |
| `@ptrCast(T, p)` | `@ptrCast(p)` |
| `@as(T, x)` | still `@as(T, x)` |
| `@bitCast(T, x)` | `@bitCast(x)` |
| `@errorToInt` | `@intFromError` |
| `@intToError` | `@errorFromInt` |
| `@boolToInt` | `@intFromBool` |
| `@enumToInt` | `@intFromEnum` |
| `@intToEnum` | `@enumFromInt` |
| `@floatToInt` | `@intFromFloat` |
| `@intToFloat` | `@floatFromInt` |
| `@ptrToInt` | `@intFromPtr` |
| `@intToPtr` | `@ptrFromInt` |

If a snippet uses the old names, it is pre-0.11. Translate to the `@*From*` or `@*FromInt` form.

## `usingnamespace` is gone

0.16 removed `usingnamespace`. If you see it in tutorials, the replacement is either explicit re-exports (`pub const Foo = @import("foo.zig").Foo;`) or a trait-like pattern with methods on the imported namespace.
