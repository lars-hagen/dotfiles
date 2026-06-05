# Zig Quirks and Gotchas (0.16)

Edge cases, LLM-common mistakes, and workarounds. Read alongside `SKILL.md` top rules and `language-0.16.md`.

## `ArrayList` `.init(gpa)` "no longer works"

Claim: `std.ArrayList(u8).init(gpa)` compiles but methods complain about missing allocator argument.

Reality: 0.16 made `ArrayList` unmanaged by default. `.init` was removed from the unmanaged variant. Use:

```zig
var list: std.ArrayList(u8) = .empty;
defer list.deinit(gpa);
try list.append(gpa, x);
```

Or switch to the managed form explicitly (note the lowercase `array_list`; `std.ArrayList` is a function, not a namespace, so `std.ArrayList.Managed` does not resolve):

```zig
var list: std.array_list.Managed(u8) = .init(gpa);
defer list.deinit();
try list.append(x);
```

Same applies to `HashMap`, `AutoHashMap`, `StringHashMap`, `ArrayHashMap`, `BoundedArray`, etc. Unmanaged is the default.

## Flushing writers

Buffered writers silently drop bytes if the process exits without flushing. Always:

```zig
var fw: std.Io.File.Writer = .init(.stdout(), init.io, &buf);
const out = &fw.interface;
defer out.flush() catch {};  // best-effort on scope exit
```

Note `std.process.exit` does not run `defer`. If you must call it, flush explicitly first:

```zig
try out.flush();
std.process.exit(2);
```

## `std.debug.print` writes to stderr

Expected on Unix. Less obvious: in Debug builds it stacktraces on error; in Release it uses a simpler path. For CLI user-facing output, use a proper stdout `Writer`. For internal debug/help/version, `std.debug.print` is fine and avoids buffer management.

## `--release` with no value

`zig build --release` only works if `build.zig` sets `preferred_optimize_mode`:

```zig
const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
```

Without that option, `--release` (no value) errors out. `--release=small` always works.

Plain `zig build` is **always** Debug unless you pass `--release=*` or `-Doptimize=Release*`. `preferred_optimize_mode` does not change the default for bare `zig build`.

## Integer casts: result-location inference

0.12+ removed the explicit target-type argument. If you see `@intCast(u32, x)` in a tutorial, it is pre-0.12:

```zig
// Old: @intCast(u32, x)
// New: result-location form
const y: u32 = @intCast(x);

// Or inline:
const z = @as(u32, @intCast(x));
```

Same for `@ptrCast`, `@bitCast`, `@floatCast`, `@truncate`, `@enumFromInt`, `@intFromEnum`, etc.

## `usingnamespace` gone

If a tutorial says `usingnamespace @import("other.zig");`, that no longer compiles in 0.16. Replace with explicit imports:

```zig
const other = @import("other.zig");
pub const Foo = other.Foo;
pub const bar = other.bar;
```

## Function pointers must be explicit `*const fn`

`fn (X) Y` is a function type. A function pointer is `*const fn (X) Y`:

```zig
const Callback = *const fn (x: i32) void;
// or
const Callback = *const fn (i32) void;
```

Plain `fn (X) Y` at runtime is illegal; the compiler requires the pointer form.

## `[]const u8` vs `[*:0]const u8` vs `[:0]const u8`

Three different C-string-shaped types:

- `[]const u8` - slice (pointer + length). No guaranteed terminator.
- `[*:0]const u8` - unknown-length pointer with NUL terminator. Common for C APIs and string literals.
- `[:0]const u8` - slice with NUL terminator just past the end. Mix of the two.

Rules:

- String literals have type `*const [N:0]u8`; they coerce to all three.
- `std.mem.span(c_str)` converts `[*:0]const u8` -> `[:0]const u8` (scans for the terminator).
- `gpa.dupeZ(u8, slice)` copies a slice and adds a NUL terminator, returning `[:0]u8`.

## Forgetting `.winapi` on Windows callbacks

The callback compiles with the C ABI. On 32-bit x86 Windows this passes args on the stack in the wrong direction; Win32 will read garbage. Always:

```zig
fn wndProc(hwnd: HWND, msg: UINT, wp: WPARAM, lp: LPARAM) callconv(.winapi) LRESULT { ... }
```

## `extern struct` layout pitfalls

Zig's default `struct` has undefined layout; `extern struct` guarantees C-compatible layout. Rules:

- Fields in declaration order.
- Packing matches the target's C ABI (typically natural alignment).
- Bit-fields not supported; use `packed struct` for those.

Copy field order from the SDK header exactly; the compiler will not warn on a field reorder.

## `b.default_step` cycle

Trap:

```zig
copy_step.dependOn(b.getInstallStep());
b.default_step = copy_step;
// If you ALSO do this, you have a cycle:
b.getInstallStep().dependOn(&copy.step);  // WRONG
```

The build runner detects cycles and errors out. Wire steps in one direction only.

## Linker errors "undefined symbol CreateWindowExW"

Missing `mod.linkSystemLibrary("user32", .{});`. Note that in 0.16 this method is on `*Module`, not on `*Step.Compile`. Call it before `b.addExecutable`.

## `zig fmt` mangles my code

`zig fmt` is canonical. There are no style options. If it reformats your code differently than expected, your formatting was non-canonical. Either accept the canonical form or wrap the block in `// zig fmt: off` / `// zig fmt: on` comments to preserve manual alignment (e.g. for tables).

## Slow first build

The first `zig build` in a project downloads the bundled toolchain components and builds the build runner. Subsequent builds are cached. To purge: delete `.zig-cache/` and the global cache (`~/.cache/zig/` by default; run `zig env` to confirm `global_cache_dir`).

## `@cImport` is slow

Including big headers (`<windows.h>`, `<Cocoa/Cocoa.h>`) pulls in thousands of declarations. Prefer:

1. Hand-writing `extern` declarations for the 5-20 functions you use.
2. `zig translate-c` once, commit the output, edit it to keep only what you need.

## Panic stack traces missing

Debug builds emit a full stack trace on panic from the binary's debug info. If you see "Unable to dump stack trace: debug info stripped", you stripped symbols: either build with `-O Debug`, or set `.strip = false` in `createModule`.

## Compile time is high

The Zig compiler is single-threaded per compilation unit. `zig build` can build modules in parallel (via the build graph), but a single big module compiles serially. Strategies:

- Split into multiple modules, each built in parallel.
- Cache: `.zig-cache/` hash-addresses everything; rebuilds are fast if nothing changed.
- Turn off `-freference-trace` if you are compiling repeatedly in a tight loop.

## `try` inside comptime

`try` in a `comptime` block works, but the error must be resolvable at comptime. Runtime errors in comptime are a compile error. Use `comptime catch` or restructure.

## `error: expected type 'X', found 'X'`

Almost always means you have two different instantiations of the same generic, typically because you re-imported something differently. Check imports; use a single named const for each type.

## `@compileError` on missing declarations after upgrade

When Zig breaks an API, failing code often gets a `@compileError` message telling you what to use instead. Read it literally; the compiler maintainers add those hints for exactly this migration path.

## Running exit cleanup

`std.process.exit` is abrupt. For real cleanup use:

```zig
pub fn main(init: std.process.Init) !u8 {
    _ = init;
    defer cleanup();
    return runApp() catch |err| {
        std.debug.print("error: {s}\n", .{@errorName(err)});
        return 1;
    };
}
```

Returning `u8` from `main` gives Zig a chance to run `defer` and flush writers before exiting.
