---
name: zig
description: >-
  Zig 0.16.0 (April 2026). Systems programming with the Zig compiler: native
  executables, libraries, cross-compilation, C interop (zig cc), build.zig,
  and testing. Covers breaking 0.16 API changes (new main signature with
  std.process.Init, Args.Iterator, Environ.Map, Module.linkSystemLibrary,
  unmanaged ArrayList, std.Io.File writers), build system patterns (custom
  steps, install-to-PATH, --release flags), and cross-compilation via zig
  targets (including cross-compiling to Windows/Linux from macOS).
  Corrects common LLM mistakes inherited from pre-0.16 API surfaces.
---

# Zig (0.16.0)

Zig is a systems programming language and toolchain: compiler, build system, cross C/C++ compiler (`zig cc`), and test runner in one binary. This skill is maintained for 0.16.0 and was verified by running `zig` commands and grepping the bundled `std` source on the user's machine.

Authoritative sources:

- Language reference: <https://ziglang.org/documentation/master/>
- Stdlib: <https://ziglang.org/documentation/master/std/>
- Local std source (ultimate source of truth): run `zig env` and read `lib_dir`; std lives in `<lib_dir>/std/`. Grep it when the online docs lag.
- Release notes: <https://ziglang.org/download/> (latest 0.16.x)
- Community forum: <https://ziggit.dev/>

## Top rules

Read these before touching Zig code. Agents get most of these wrong because 0.15 and earlier tutorials are still the majority on the web.

1. **0.16 broke a lot of std APIs.** If a tutorial says `std.process.argsAlloc`, `std.heap.GeneralPurposeAllocator`, `std.process.getEnvVarOwned`, `std.io.getStdOut`, or `std.ChildProcess`, it is pre-0.16 and wrong. The replacements are in [references/language-0.16.md](references/language-0.16.md).
2. **`pub fn main` now takes a `std.process.Init`.** Not `[]const []const u8`. Not nothing. Shape: `pub fn main(init: std.process.Init) !void`. Args come from `init.minimal.args`, an arena from `init.arena`, a gpa from `init.gpa`, env from `init.environ_map`, Io from `init.io`.
3. **`ArrayList(T)` is unmanaged by default in 0.16.** Init with `.empty`, methods take `gpa` explicitly: `list.append(gpa, x)`, `list.deinit(gpa)`. The managed form is `std.array_list.Managed(T)` (note the lowercase module path; `std.ArrayList` is a function, not a namespace, so `.Managed` does not resolve on it).
4. **`linkSystemLibrary` lives on `*Module`, not `*Compile`.** Call `mod.linkSystemLibrary("sqlite3", .{})` before building the executable. Old `exe.linkSystemLibrary(...)` no longer exists.
5. **Release modes have a new CLI surface.** End users pass `--release=small`, `--release=fast`, `--release=safe`, or bare `--release` (uses `preferred_optimize_mode` from `standardOptimizeOption`). `-Doptimize=ReleaseSmall` still works but is the "internal" form.
6. **`b.default_step` is a reassignable pointer.** To make plain `zig build` do something custom, `b.default_step = my_step;` after wiring `my_step` up. Do not `my_step.dependOn(b.getInstallStep())` and then set `b.default_step = my_step` if `my_step` already depends on install; that is fine, but do not then make install depend on `my_step`; that creates a cycle.
7. **stdout is now `std.Io.File.stdout()` plus a buffered `Writer`.** Stdio moved from `std.io.getStdOut()` to the new `std.Io` subsystem. For CLI help or version output, prefer `std.debug.print` unless you specifically need stdout.

## Decision Guide

| Goal | Command / approach |
|------|--------------------|
| Create a new project | `zig init` (scaffolds `build.zig`, `build.zig.zon`, `src/main.zig`, `src/root.zig`) |
| Debug build | `zig build` |
| Smallest release binary | `zig build --release=small` |
| Fastest release binary | `zig build --release=fast` |
| Safe release (keeps runtime checks) | `zig build --release=safe` |
| Run the exe the build produces | `zig build run` (forwarding args: `zig build run -- arg1 arg2`) |
| Run tests | `zig build test` |
| One-shot test of a file | `zig test src/foo.zig` |
| Cross-compile to Linux x86_64 | `zig build -Dtarget=x86_64-linux-gnu --release=small` |
| Cross-compile to musl | `zig build -Dtarget=x86_64-linux-musl --release=small` |
| Use Zig as a C compiler | `zig cc -O2 -o app app.c` |
| Translate C headers to Zig | `zig translate-c header.h > bindings.zig` |
| Format code | `zig fmt src/` |
| List targets | `zig targets` (emits ZON; use `| head` to peek) |
| Inspect toolchain | `zig env`, `zig version` |
| Add a system library | `mod.linkSystemLibrary("sqlite3", .{})` inside `build.zig` |
| Install exe to `~/.local/bin` | Custom `install-local` step running a `cp` system command after install. See [references/build-system.md](references/build-system.md). |
| Parse CLI args | `init.minimal.args.toSlice(arena)` or `Args.Iterator.initAllocator(init.minimal.args, init.gpa)`. See [references/cli-patterns.md](references/cli-patterns.md). |
| Read an environment variable | `init.environ_map.get("VAR")` (returns `?[]const u8`). In `build.zig`: `b.graph.environ_map.get("VAR")`. |
| Call a C library | `@cImport({ @cInclude("header.h"); })` plus `mod.linkSystemLibrary(...)` or `.link_libc = true` in `createModule`. See [references/c-interop.md](references/c-interop.md). |

## Version Awareness

Zig pre-1.0 breaks APIs at almost every minor release. Pin your minimum and detect cleanly.

**`build.zig.zon`:**

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0x123456789abcdef0,  // never change, regenerated on fork
    .minimum_zig_version = "0.16.0",
    .dependencies = .{},
    .paths = .{ "build.zig", "build.zig.zon", "src" },
}
```

**Detect the compiler version in `build.zig`:**

```zig
const required: std.SemanticVersion = .{ .major = 0, .minor = 16, .patch = 0 };
if (@import("builtin").zig_version.order(required) == .lt) {
    @compileError("This project requires Zig 0.16.0 or newer");
}
```

**0.15 to 0.16 transition cheat sheet:**

| 0.15 and earlier | 0.16 |
|------------------|------|
| `pub fn main() !void` with `std.process.argsAlloc(gpa)` | `pub fn main(init: std.process.Init) !void`; `try init.minimal.args.toSlice(arena)` |
| `std.heap.GeneralPurposeAllocator(.{}){}` | Use `init.gpa` (already a `DebugAllocator` in Debug), or `std.heap.DebugAllocator(.{})` directly |
| `std.process.getEnvVarOwned(gpa, "X")` | `init.environ_map.get("X")` (non-owning) or `init.minimal.environ.getAlloc(gpa, "X")` |
| `std.io.getStdOut().writer()` | `std.Io.File.stdout()` plus `File.Writer` with a buffer |
| `std.ArrayList(u8).init(gpa)` / `list.deinit()` | `var list: std.ArrayList(u8) = .empty;` / `list.deinit(gpa);` |
| `list.append(x)` | `list.append(gpa, x)` |
| `callconv(.Stdcall)` or `std.os.windows.WINAPI` | `callconv(.winapi)` |
| `exe.linkSystemLibrary("user32")` | `mod.linkSystemLibrary("user32", .{})` on the `*Module` |
| `b.standardReleaseOptions()` | `b.standardOptimizeOption(.{})` |
| `std.ChildProcess` | `std.process.Child` |
| `mod.linkLibC()` | `.link_libc = true` in `createModule` options, or `mod.linkSystemLibrary("c", .{})` |
| `std.time.nanoTimestamp()` / `milliTimestamp()` | `std.Io.Clock.now(.awake, io)` returns an `Io.Timestamp`; use `.durationTo(other)` for diffs |
| `std.Thread.sleep(ns)` | `init.io.sleep(.fromMilliseconds(ms), .awake)` |
| `std.testing.refAllDeclsRecursive(@This())` | Removed; recurse manually with `inline for` over `@typeInfo(@This()).@"struct".decls` calling `refAllDecls` |

## Common Commands

| Task | Command |
|------|---------|
| Init project | `zig init` |
| Build default step | `zig build` |
| Build release (small/fast/safe) | `zig build --release=small` |
| Build and run | `zig build run` |
| Build, run, pass args | `zig build run -- --flag value` |
| Run all tests | `zig build test` |
| Test a single file | `zig test src/util.zig` |
| Cross-compile | `zig build -Dtarget=<triple>` |
| Format | `zig fmt .` |
| Version | `zig version` |
| Environment | `zig env` |
| List targets | `zig targets` |
| Drop-in C compiler | `zig cc` |
| Drop-in C++ compiler | `zig c++` |
| C header to Zig | `zig translate-c foo.h` |
| Fetch a dependency | `zig fetch --save <url>` |
| Ast-check (fast syntax check) | `zig ast-check file.zig` |

## Built-in capabilities (stdlib)

Before reaching for a third-party library, check what std ships. These are all in `std.*` unless noted.

| Need | Use | Notes |
|------|-----|-------|
| JSON | `std.json` | Scanner, dynamic `Value`, `parseFromSlice`, `parseFromSliceLeaky`, `Stringify`. |
| ZON (Zig Object Notation) | `std.zon` | `parse`, `stringify`, `Serializer`. Native config format. |
| HTTP client | `std.http.Client` | Full client with TLS. |
| HTTP server | `std.http.Server` | Lower-level; pair with `std.Io.net`. |
| TLS | `std.crypto.tls` | Pure-Zig TLS 1.3. |
| Hashing | `std.crypto.hash` | SHA-2/3, Blake2/3, etc. Use `std.crypto.hash.sha2.Sha256`. |
| AEAD | `std.crypto.aead` | ChaCha20-Poly1305, AES-GCM. |
| Password hashing | `std.crypto.pwhash` | argon2, bcrypt, scrypt. |
| ECC, Ed25519, X25519 | `std.crypto.ecc`, `std.crypto.sign.Ed25519` | |
| Compression | `std.compress` | `flate` (gzip/deflate/zlib), `xz`, `zstd`, `lzma`, `lzma2`. |
| Tar | `std.tar` | Create and extract. |
| Base64/hex | `std.base64`, `std.fmt.fmtSliceHexLower` | |
| PRNG | `std.Random` | `DefaultPrng = Xoshiro256`, `DefaultCsprng = ChaCha`. Note `Random` is capitalized (was `std.rand` in older versions). |
| Unicode | `std.unicode` | UTF-8, UTF-16 LE, including `utf8ToUtf16LeStringLiteral`. |
| Regex | **Not in std.** | Use `mvzr` (minimal) or `zig-regex` via `build.zig.zon`. |
| Arg parsing | `std.process.Args.Iterator` + manual | Or community `clap`. See [references/cli-patterns.md](references/cli-patterns.md). |
| Threads | `std.Thread` | `spawn`, `Mutex`, `RwLock`, `Semaphore`. |
| Atomics | `std.atomic.Value(T)` | Methods: `.load(.seq_cst)`, `.store(1, .seq_cst)`, `.fetchAdd`, `.cmpxchgStrong`. |
| Child processes | `std.process.Child`, `std.process.spawn`, `std.process.run` | `std.process.run(gpa, io, .{...})` for one-shot capture. `std.process.spawn(io, .{...})` returns a `Child` for lower-level stdio piping. |
| Files and dirs | `std.Io.Dir`, `std.Io.File` | Opened via `init.io`. |
| Formatting | `std.fmt` | `bufPrint`, `allocPrint`, `parseInt`, `parseFloat`. |
| Math | `std.math` | Usual. |
| Collections | `std.ArrayList`, `std.AutoHashMap`, `std.StringHashMap`, `std.ArrayHashMap` | **Unmanaged by default in 0.16.** Managed variant for ArrayList: `std.array_list.Managed(T)`. |
| Allocators | `std.heap.DebugAllocator`, `std.heap.ArenaAllocator`, `std.heap.FixedBufferAllocator`, `std.heap.page_allocator`, `std.heap.c_allocator`, `std.heap.smp_allocator` | No `GeneralPurposeAllocator`. |
| Io abstraction | `std.Io` | New in 0.16: unified FS, net, time, concurrency interface. |

For signatures, examples, and gotchas, see [references/stdlib.md](references/stdlib.md).

## Setup on this machine

Zig 0.16.0 on macOS (Apple Silicon).

- Install: `brew install zig zls` (zls is the language server; it tracks the Zig release, update in lockstep).
- Toolchain paths: run `zig env`. `lib_dir` is the std source root (grep `<lib_dir>/std/` when docs lag); `global_cache_dir` is the build cache.
- Updates: `brew upgrade zig zls`.
- Cross-compiling needs nothing extra; the target backends ship with the compiler.

**Cache locations:**

- Global cache: `~/.cache/zig/` by default. Override with `ZIG_GLOBAL_CACHE_DIR`.
- Local cache: `<project>/.zig-cache/`. Override with `ZIG_LOCAL_CACHE_DIR`.

## Project Scaffold

### Canonical `zig init`

`zig init` produces four files in the current directory. File-by-file purpose:

- `build.zig` - build graph. Defines the exe, modules, `run`, and `test` top-level steps.
- `build.zig.zon` - package manifest. Name, version, fingerprint, minimum Zig version, dependencies, `paths` for packaging.
- `src/main.zig` - CLI entrypoint with the new `pub fn main(init: std.process.Init) !void` signature. Demonstrates arena use, args, and buffered stdout via `std.Io.File.Writer`.
- `src/root.zig` - library root, re-exports public API for packages that depend on this module.

If building a pure CLI, you can delete `src/root.zig` and collapse `mod` / `exe.root_module` into one `createModule` call in `build.zig`.

### Minimal CLI scaffold

A slimmed-down version that drops the library module and the fuzz tests. Use this as the starting point for a single-binary CLI.

`build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    });

    const exe = b.addExecutable(.{ .name = "mycli", .root_module = mod });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    if (b.args) |a| run.addArgs(a);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run.step);

    const tests = b.addTest(.{ .root_module = mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
```

`build.zig.zon`:

```zig
.{
    .name = .mycli,
    .version = "0.1.0",
    .fingerprint = 0xabc123def456,  // placeholder: on first `zig build`, Zig rejects this and prints the real value to paste in. Never change it afterwards.
    // Changing this has security and trust implications.
    .minimum_zig_version = "0.16.0",
    .dependencies = .{},
    .paths = .{ "build.zig", "build.zig.zon", "src" },
}
```

`src/main.zig` (verified runnable on 0.16.0):

```zig
const std = @import("std");
const Io = std.Io;

const VERSION = "0.1.0";

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    var out_buf: [4096]u8 = undefined;
    var out_fw: Io.File.Writer = .init(.stdout(), init.io, &out_buf);
    const out = &out_fw.interface;
    defer out.flush() catch {};

    // Skip argv[0].
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--help") or std.mem.eql(u8, a, "-h")) {
            try out.print("mycli {s}\nUsage: mycli [--help] [--version]\n", .{VERSION});
            return;
        }
        if (std.mem.eql(u8, a, "--version") or std.mem.eql(u8, a, "-v")) {
            try out.print("{s}\n", .{VERSION});
            return;
        }
        try out.print("unknown argument: {s}\n", .{a});
        std.process.exit(2);
    }

    try out.print("hello from mycli\n", .{});
}

test "sanity" {
    try std.testing.expect(1 + 1 == 2);
}
```

`.gitignore`:

```
zig-out/
.zig-cache/
```

## Common Misconceptions

Agents and tutorials get these wrong. Reality column is verified on 0.16.0.

| Claim | Reality |
|-------|---------|
| "Use `std.process.argsAlloc(gpa)` to get args" | **Removed in 0.16.** Use `init.minimal.args.toSlice(arena)` or `Args.Iterator.initAllocator`. |
| "`std.heap.GeneralPurposeAllocator(.{}){}` is the default allocator" | **Removed.** Use `init.gpa`, or `std.heap.DebugAllocator(.{})` for explicit construction, or `std.heap.page_allocator` / `std.heap.smp_allocator`. |
| "`main` is `pub fn main() !void`" | **Changed.** Signature is `pub fn main(init: std.process.Init) !void`. The older form still compiles when you need zero parameters, but gives up access to the provided arena, gpa, Io, env, and args. |
| "Use `std.io.getStdOut().writer()` for stdout" | **Moved.** Use `std.Io.File.stdout()` plus a `std.Io.File.Writer` with a buffer. For `std.debug.print`-style writes, that function still exists and writes to stderr. |
| "`std.ArrayList(T).init(gpa)`" | **Default is unmanaged.** Use `.empty` and pass `gpa` to each method. Managed form: `std.array_list.Managed(T).init(gpa)`. |
| "`exe.linkSystemLibrary("user32")`" | **Moved to Module.** `mod.linkSystemLibrary("user32", .{})`. Call it before `b.addExecutable`. |
| "`callconv(.Stdcall)` or `std.os.windows.WINAPI` for Win32" | **Use `callconv(.winapi)`.** The `CallingConvention` union picks the right ABI per target. |
| "`std.ChildProcess` runs subprocesses" | **Renamed.** `std.process.Child`. |
| "`std.process.getEnvVarOwned` is the way to read env vars" | **Removed at std.process top level.** In `main`, use `init.environ_map.get` (non-owning) or `init.minimal.environ.getAlloc(gpa, key)`. In `build.zig`, use `b.graph.environ_map.get`. |
| "Add `exe.strip = true`" | **Strip is on the module, not the compile step.** Set `.strip = true` in `createModule`/`addModule`. |
| "`b.default_step` is read-only" | **It is a reassignable pointer.** Set `b.default_step = my_step;` to change what bare `zig build` runs. |
| "`-Drelease` triggers release mode" | **No; use `--release` or `-Doptimize`.** `--release=small/fast/safe` is the end-user switch. `preferred_optimize_mode` in `standardOptimizeOption` only affects bare `--release` with no value. Plain `zig build` is still Debug. |
| "Zig has `std.rand.DefaultPrng`" | **Renamed `std.Random.DefaultPrng`.** The module is capitalized. |
| "Regex is in stdlib" | **Not in stdlib.** Pull in a community package (e.g. `mvzr`, `zig-regex`). |

### What Zig does NOT have (vs Rust/Go)

- A package registry. Dependencies are fetched by URL + hash via `build.zig.zon`; there is no central registry.
- A standard async runtime. `std.Io` is the unified I/O/concurrency interface; runtimes are pluggable (single-threaded, `Threaded`, `Evented`).
- A stable ABI. 0.x releases break APIs. Pin `minimum_zig_version`.
- Built-in regex, YAML, or TOML parsers. JSON and ZON are in std.
- A doc-comment runner on par with `cargo doc`. `zig std` launches a local docs browser over the stdlib.

## Build System Highlights

See [references/build-system.md](references/build-system.md) for full patterns. Key points that agents miss:

- A `*Step.Compile` is built from a `*Module`. Put libraries, include paths, C source files, and `strip` on the module, not the compile step.
- `b.installArtifact(exe)` wires the default install step. `b.getInstallStep()` returns that step so your own steps can depend on install completing.
- To make a custom step the default: `b.default_step = my_step;`. No cycle: ensure `my_step.dependOn(b.getInstallStep())` and do not make install depend on `my_step` in return.
- Read env vars in `build.zig` with `b.graph.environ_map.get("HOME")`. Do not import `std.process` and try `getEnvVarOwned`; it no longer exists there.
- For cross-compile, `b.resolveTargetQuery(.{ .os_tag = .linux, .abi = .gnu, .cpu_arch = .x86_64 })` or accept `-Dtarget=` via `standardTargetOptions`.

## Testing

See [references/testing.md](references/testing.md) for flags, test filtering, fuzz tests, and CI patterns.

- `test "name" { ... }` blocks sit inside any `.zig` file.
- `zig build test` runs every test in every module declared in `build.zig`.
- `zig test path/to/file.zig` runs tests in just that file.
- `--test-filter "substr"` to narrow down.
- `std.testing.allocator` is a leak-checking allocator for test-only use.
- Fuzz tests use `std.testing.fuzz(ctx, fn, .{})`; invoke with `zig build test --fuzz`.

## Cross-compilation

See [references/cross-compile.md](references/cross-compile.md) for target triples, glibc version pinning, and common recipes.

```bash
zig build -Dtarget=x86_64-linux-gnu --release=small
zig build -Dtarget=x86_64-linux-musl --release=small
zig build -Dtarget=aarch64-macos    --release=small
zig build -Dtarget=x86_64-windows-gnu --release=small
zig build -Dtarget=wasm32-wasi      --release=small
```

Pinning glibc: `-Dtarget=x86_64-linux-gnu.2.17` for RHEL 7 compatibility.

## C Interop

See [references/c-interop.md](references/c-interop.md). Short version:

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("sqlite3.h");
});
// ...
_ = c.printf("hi\n");
```

```zig
// in build.zig
const mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
mod.linkSystemLibrary("sqlite3", .{});
mod.addIncludePath(b.path("vendor/include"));
mod.addCSourceFile(.{ .file = b.path("vendor/sqlite3.c"), .flags = &.{"-std=c11"} });
```

`zig cc` is a drop-in C compiler for the target you pass via `-target`. `zig translate-c header.h` converts a C header to Zig source.

## CLI Patterns

See [references/cli-patterns.md](references/cli-patterns.md) for subcommands, exit codes, signal handling.

Common patterns:

- Iterator-style args: `var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa); defer it.deinit();`
- Slice-style args: `const args = try init.minimal.args.toSlice(arena);` (uses the arena, no manual free).
- Exit with code: `std.process.exit(2);` (does not run deferred blocks; flush writers before calling).
- Panic on fatal: `std.process.fatal("bad thing: {s}", .{msg});` prints to stderr and exits 1.

## Known Quirks

See [references/quirks.md](references/quirks.md) for the full list. Highlights:

1. **`--release` without a value uses `preferred_optimize_mode`.** If your `build.zig` passes `.preferred_optimize_mode = .ReleaseSmall`, then `zig build --release` means "small". Plain `zig build` is still Debug.
2. **`ArrayList` managed-vs-unmanaged confusion.** 0.16 made unmanaged the default. Tutorials saying `std.ArrayList(T).init(gpa)` need `std.array_list.Managed(T).init(gpa)`, or, better, migrate to the unmanaged form and pass `gpa` to each method.
3. **Writer buffers must be flushed.** `std.Io.File.Writer` and its `interface` writer buffer output. Without `try out.flush()`, stdout may drop bytes at program exit.
4. **`callconv(.winapi)` applies differently per arch.** Relevant only when cross-compiling to Windows: on 32-bit x86 it is `x86_stdcall`, on x64 it is the Win64 ABI. Use `.winapi` and let the compiler pick per target.
5. **Subsystem for cross-compiled Windows GUI apps.** When targeting Windows, set `exe.subsystem = .Windows;` on the `*Step.Compile` from `addExecutable` to skip the console window. It is a field on the compile step, not in `ExecutableOptions`. Default is `.Console`.
