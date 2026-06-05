# C Interop (Zig 0.16)

Zig ships a full C compiler (`zig cc`), a C translator (`zig translate-c`), and first-class C-header imports (`@cImport`). No separate `bindgen` step, no `build.rs`.

## `@cImport`

Embed C headers directly in Zig source. The compiler parses them, emits Zig declarations, and caches the result.

```zig
const c = @cImport({
    @cDefine("_GNU_SOURCE", "1");
    @cInclude("stdio.h");
    @cInclude("sqlite3.h");
});

pub fn main(init: std.process.Init) !void {
    _ = init;
    _ = c.printf("hi from C\n");

    var db: ?*c.sqlite3 = null;
    if (c.sqlite3_open(":memory:", &db) != c.SQLITE_OK) {
        @panic("open failed");
    }
    defer _ = c.sqlite3_close(db);
}
```

`@cImport` rules:

- One `@cImport` per module is the convention; Zig deduplicates, but multiple calls create separate translation units.
- `@cDefine(name, value)` injects a `#define` before the include.
- `@cInclude(path)` is equivalent to `#include <path>` (angle-bracket form).
- Anything declared `static inline` in the header is translated; functions without a body (external) become `extern` declarations linked at build time.

## build.zig for C Interop

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    mod.linkSystemLibrary("sqlite3", .{});
    mod.addIncludePath(b.path("vendor/include"));

    const exe = b.addExecutable(.{ .name = "sqldemo", .root_module = mod });
    b.installArtifact(exe);
}
```

`linkLibC()` pulls in the C runtime for the target. On Windows (MSVC ABI) it links the MSVC CRT; on MinGW it links mingw-w64; on Linux it uses glibc or musl depending on `-Dtarget=...-musl`.

## Vendoring C Sources

For a C library you want to build from source rather than link against the system copy:

```zig
mod.addCSourceFile(.{
    .file = b.path("vendor/sqlite3.c"),
    .flags = &.{
        "-std=c11",
        "-DSQLITE_THREADSAFE=1",
        "-DSQLITE_ENABLE_FTS5",
    },
});
mod.addIncludePath(b.path("vendor"));
// Set `.link_libc = true` in the corresponding `b.createModule(.{ ... })` call.
```

Multiple files:

```zig
mod.addCSourceFiles(.{
    .root = b.path("vendor/foo"),
    .files = &.{ "a.c", "b.c", "c.c" },
    .flags = &.{ "-std=c11", "-Wall" },
});
```

## `zig cc` as a Drop-in Compiler

`zig cc` is clang with Zig's cross-compile defaults. It honors `-target`, `--sysroot`, and ordinary clang flags:

```bash
zig cc -O2 -o app app.c
zig cc -target x86_64-linux-gnu -O2 -o app app.c     # cross to Linux from Windows
zig cc -target aarch64-linux-musl -O2 -o app app.c   # musl for static linking
zig c++ -O2 -o app app.cpp
```

Use as `$CC` / `$CXX` in Makefiles or CMake:

```bash
CC='zig cc' CXX='zig c++' ./configure --target=x86_64-linux-gnu
```

For projects with glibc ABI pinning, `zig cc -target x86_64-linux-gnu.2.17` gives a binary that loads on glibc 2.17+ (RHEL 7 era). See [cross-compile.md](cross-compile.md).

## `zig translate-c`

Converts a C header or source file to Zig. Faster than `@cImport` for one-shot extraction, and the result is pure Zig source you can edit.

```bash
zig translate-c -I/usr/include -lc mylib.h > mylib_bindings.zig
```

Pitfalls: translate-c's output is mechanical. Function pointers and complex macros may need manual cleanup.

## Function Pointers

C callbacks in Zig use `*const fn`:

```zig
const Callback = *const fn (data: *anyopaque) callconv(.c) c_int;

extern fn register_callback(cb: Callback, user: *anyopaque) c_int;

fn myCallback(data: *anyopaque) callconv(.c) c_int {
    _ = data;
    return 0;
}

_ = register_callback(&myCallback, undefined);
```

`callconv(.c)` is the portable C calling convention. Use `.winapi` for Win32.

## Pointers and Slices

C has `T*`. Zig distinguishes:

- `*T` - non-null single-item pointer.
- `[*]T` - unknown-length array pointer; does not carry a length.
- `[*:0]T` - null-terminated pointer (C strings: `[*:0]const u8`).
- `[]T` - slice (pointer + length).
- `?*T` - optional pointer; use this when C APIs return or accept NULL.

Common conversions:

```zig
// C string to Zig slice:
const cs: [*:0]const u8 = c_function();
const slice: []const u8 = std.mem.span(cs);

// Zig slice to C string (needs null-termination):
const zig_str = "hello";
const c_str: [*:0]const u8 = zig_str;  // works for string literals

// Runtime: dupeZ to NUL-terminate into an allocator.
const c_str2 = try gpa.dupeZ(u8, runtime_str);
defer gpa.free(c_str2);
_ = c_function_ptr(c_str2.ptr);
```

## `extern` Declarations

When you do not want a whole `@cImport` just to call one function, declare it directly:

```zig
extern fn malloc(size: usize) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) void;

// Use:
const p = malloc(128) orelse return error.OutOfMemory;
defer free(p);
```

For functions from a specific library, use `extern "libname"`:

```zig
extern "ssl" fn SSL_library_init() callconv(.c) c_int;
```

The library string must match what you pass to `mod.linkSystemLibrary`.

## C Types

Zig exposes C primitive type aliases in `std.c` and as builtins. The builtins are the canonical form:

```zig
// Builtin aliases (no import needed):
// c_char, c_short, c_ushort, c_int, c_uint, c_long, c_ulong,
// c_longlong, c_ulonglong, c_longdouble.
// Width is target-defined (whatever the target C ABI says).

const x: c_int = 42;
const y: c_long = 123;
// anyopaque is the equivalent of C's `void` in "void *" pointers.
const p: *anyopaque = @ptrFromInt(0x1000);
_ = .{ x, y, p };
```

More ergonomic: just `@cImport` the header you care about and use `c.*` types directly.

## Static Linking Example

Self-contained Linux binary, no libc dependency, using Zig's musl runtime:

```bash
zig build-exe src/main.zig -target x86_64-linux-musl -O ReleaseSmall -fstrip
```

The result runs on any Linux 3.2+ with no dynamic library dependencies.

## Windows C Runtime

On Windows, pick an ABI:

- `-Dtarget=x86_64-windows-msvc`: uses MSVC CRT. Needs MSVC installed (or the MSVC build tools) for some cases; for simple CRT-only usage, Zig ships enough to build without it.
- `-Dtarget=x86_64-windows-gnu`: uses mingw-w64 CRT, fully self-contained. Recommended for most cases.

## When NOT to `@cImport`

Heavy, transitively included headers (e.g. `<windows.h>`, `<Cocoa/Cocoa.h>`) can slow compilation dramatically and pull in hundreds of declarations. Strategies:

1. `zig translate-c` once, copy the subset you need, drop it into a `.zig` file, and commit that.
2. Write `extern` declarations by hand for the 5-20 functions you actually call.
3. Use `@cImport` only for focused third-party libs (SQLite, cURL, OpenSSL).
