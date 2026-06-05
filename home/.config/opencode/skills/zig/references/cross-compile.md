# Cross-compilation (Zig 0.16)

Zig's flagship feature: cross-compile to any target from any host, with no external toolchain. The Zig distribution bundles libc headers and source for glibc, musl, mingw-w64, and wasi-libc, plus a C compiler (`zig cc`) that picks the right one.

## Invocation

```bash
zig build -Dtarget=<triple> [--release=<mode>]
```

Triples are `<arch>-<os>-<abi>`. Pass `zig targets` to dump every supported combination (the output is ZON).

## Common Triples

| Target | Triple |
|--------|--------|
| Native | (omit `-Dtarget`, or `-Dtarget=native`) |
| Linux x86_64 glibc | `x86_64-linux-gnu` |
| Linux x86_64 musl (static) | `x86_64-linux-musl` |
| Linux aarch64 glibc | `aarch64-linux-gnu` |
| Linux aarch64 musl | `aarch64-linux-musl` |
| macOS x86_64 | `x86_64-macos` |
| macOS Apple Silicon | `aarch64-macos` |
| Windows x86_64 MinGW | `x86_64-windows-gnu` |
| Windows x86_64 MSVC ABI | `x86_64-windows-msvc` |
| Windows aarch64 | `aarch64-windows-gnu` |
| WASI | `wasm32-wasi` |
| Freestanding WebAssembly | `wasm32-freestanding` |
| Embedded Cortex-M | `thumb-freestanding-eabi` (with `-Dcpu=cortex_m4` etc.) |

## glibc Version Pinning

The ABI string accepts a minimum glibc version:

```bash
zig build -Dtarget=x86_64-linux-gnu.2.17 --release=small
```

This produces a binary that will load on any Linux with glibc 2.17 or newer (RHEL 7 era). Useful for distributing to enterprise environments.

Common pins:

- `.2.17` - RHEL 7, CentOS 7
- `.2.28` - RHEL 8, Ubuntu 20.04
- `.2.31` - Ubuntu 20.04 (default system glibc)
- `.2.35` - Ubuntu 22.04

## musl for Static Linking

```bash
zig build -Dtarget=x86_64-linux-musl --release=small
```

The resulting binary is fully static: no dynamic library dependencies, runs on any Linux 3.2+. No glibc version concerns.

Trade-off: musl's allocator is slower than glibc's for some workloads, and DNS resolution is more conservative.

## Windows: MSVC vs MinGW

Two ABIs are available:

- **`x86_64-windows-gnu`** (mingw-w64): Zig ships the complete toolchain. No external dependencies needed. Recommended default.
- **`x86_64-windows-msvc`**: matches the MSVC ABI. Needed when linking to libraries built with MSVC (many vendor SDKs). For CRT-only builds, Zig's bundled stubs suffice; for linking to the real MSVC libraries, install the Windows SDK and Visual Studio Build Tools.

The `monitor-blackout` project uses `x86_64-windows-gnu` and works without any MSVC installed.

## CPU Features

Refine the target with `-Dcpu=<baseline|modern|native|<model>>`:

```bash
zig build -Dtarget=x86_64-linux-gnu -Dcpu=baseline        # safe default
zig build -Dtarget=x86_64-linux-gnu -Dcpu=x86_64_v3        # AVX2, BMI2
zig build -Dtarget=x86_64-linux-gnu -Dcpu=native           # host CPU
zig build -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a72      # specific model
```

Add or remove features with `+` / `-`:

```bash
zig build -Dtarget=x86_64-linux-gnu -Dcpu=baseline+sse4_2+avx
```

## WASI

```bash
zig build -Dtarget=wasm32-wasi --release=small
wasmtime zig-out/bin/myapp.wasm arg1 arg2
```

`wasm32-wasi` gives you `std.fs`, args, and env. Pure-compute WASM without any system access: `wasm32-freestanding`.

## Freestanding / Embedded

No libc, no std.os dependencies. Good for firmware and custom runtimes:

```bash
zig build -Dtarget=thumb-freestanding-eabi -Dcpu=cortex_m4
```

In freestanding, `std.process.Init` is not a thing; write a minimal `pub fn _start() callconv(.c) noreturn { ... }` or equivalent.

## Sysroot (System Libraries)

When linking against a system library that is not in Zig's bundle (e.g. a proprietary SDK), point Zig at a sysroot:

```bash
zig build -Dtarget=aarch64-linux-gnu \
    --sysroot /path/to/rpi-sysroot \
    --libc libc.txt
```

`libc.txt` lists the relevant paths. See `zig libc --help`.

## `-Dcpu=native` vs `-target native`

- `-Dtarget=native` or no `-Dtarget`: native OS and ABI.
- `-Dcpu=native`: use every CPU feature the current machine supports.

Combining both gives the fastest possible build for the local machine but non-portable binaries. For shipping to other machines of the same OS, use `-Dcpu=baseline` or a specific ISA version.

## Cross-compile a Build That Uses C Sources

Zig's bundled clang is invoked automatically. No changes needed:

```zig
// build.zig
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});

const mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
mod.addCSourceFile(.{ .file = b.path("vendor/foo.c"), .flags = &.{"-std=c11"} });
```

```bash
zig build -Dtarget=aarch64-linux-gnu --release=small
# Produces an aarch64 Linux binary that includes foo.c compiled for that target.
```

## Inspecting Targets

```bash
zig targets              # full ZON dump (large)
zig targets | less       # paginated
zig version              # compiler version
zig env                  # paths, version, detected host triple
```

## Debug vs Release on Non-native Targets

Debug builds include runtime checks and are significantly larger. For cross-compile deliverables, almost always use `--release=small` (smallest) or `--release=fast` (fastest). `--release=safe` keeps runtime safety checks in release mode.

## Pitfalls

- **Forgetting glibc pinning**: the default `x86_64-linux-gnu` uses your host glibc version, which may be newer than your deployment target. Always pin for distributed binaries.
- **Using `native` in CI**: produces inconsistent builds across runners. Pin the target explicitly.
- **Missing libc link for cross**: if your code calls libc (via `@cImport` or a vendored `.c` file), you must link libc explicitly via `.link_libc = true` in `createModule` (or `mod.linkSystemLibrary("c", .{})`). Otherwise the linker complains about undefined C runtime symbols.
- **Windows subsystem**: cross-compiling a GUI app from Linux still needs `.subsystem = .Windows` on `addExecutable`, or you get a binary that flashes a console on launch.
- **Mixed ABIs in one build**: cannot link a `windows-gnu` module against a `windows-msvc` module. Pick one ABI for the whole build.
