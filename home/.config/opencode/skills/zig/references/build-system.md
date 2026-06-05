# Zig Build System (0.16)

Everything here has been checked against the bundled 0.16.0 std source (`zig env` -> `<lib_dir>/std/Build.zig` and `Build/Module.zig`).

## Concepts

A `build.zig` defines a build graph by calling functions on a `*std.Build`. Each call adds a step; steps are connected with `dependOn`. The build runner then executes steps in parallel where dependencies allow.

Core types:

- `*std.Build` (`b`) - the builder. Entry points: `addExecutable`, `addTest`, `addLibrary`, `addSystemCommand`, `createModule`, `addModule`, `step`, `option`.
- `*std.Build.Module` - a compilation unit: source file, target, optimize, C sources, system libs, include paths.
- `*std.Build.Step.Compile` - a compile action that produces an artifact. Created by `addExecutable`, `addLibrary`, `addTest`.
- `*std.Build.Step.Run` - a run action. Created by `addRunArtifact` or `addSystemCommand`.
- `*std.Build.Step` - generic step. Top-level steps (from `b.step(name, desc)`) are referenced by name on the CLI.

## Minimal build.zig

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{ .name = "app", .root_module = mod });
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

## Targets and Optimize

### `standardTargetOptions`

Exposes `-Dtarget=<triple>` on the CLI. Defaults to native.

```zig
const target = b.standardTargetOptions(.{});
// User can pass -Dtarget=x86_64-linux-gnu, x86_64-windows-gnu, aarch64-macos, etc.
```

### `standardOptimizeOption`

Exposes `-Doptimize=<mode>` and the shorthand `--release[=mode]`.

```zig
const optimize = b.standardOptimizeOption(.{});
// Choices: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall.

// Plain `zig build` -> Debug.
// `zig build --release` -> preferred_optimize_mode (if set) else errors.
// `zig build --release=small` -> ReleaseSmall.
// `zig build -Doptimize=ReleaseFast` -> ReleaseFast.
```

Set `preferred_optimize_mode` so bare `--release` means something sensible:

```zig
const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
```

### Hard-coded target

For a cross-only project:

```zig
const target = b.resolveTargetQuery(.{
    .os_tag = .windows,
    .abi = .gnu,
    .cpu_arch = .x86_64,
});
```

## Modules

A module bundles source, target, optimize, C sources, linked libs, include paths, and strip setting.

```zig
const mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .strip = true,                 // strip debug symbols (release builds)
    .single_threaded = false,      // opt into single-threaded mode
    .pic = null,                   // position-independent code; null = default
    .link_libc = true,             // link against libc for this module
    .imports = &.{                 // other modules importable via @import("name")
        .{ .name = "util", .module = util_mod },
    },
});
mod.linkSystemLibrary("sqlite3", .{});
mod.addIncludePath(b.path("vendor/include"));
mod.addCSourceFile(.{ .file = b.path("vendor/sqlite3.c"), .flags = &.{"-std=c11"} });
```

`addModule` vs `createModule`:

- `addModule(name, opts)` exposes the module to *consumers* of this package (used for libraries).
- `createModule(opts)` is private to the current package (used for internal organization).

## Executables, Libraries, Tests

```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_module = mod,
});
// Subsystem is a field on the compile step, not on ExecutableOptions:
exe.subsystem = .Console;        // default
// exe.subsystem = .Windows;     // GUI app, no console window

const lib = b.addLibrary(.{
    .name = "mylib",
    .linkage = .static,     // or .dynamic
    .root_module = lib_mod,
});

const tests = b.addTest(.{ .root_module = mod, .filters = &.{} });
```

Install the artifact so it lands in `zig-out/`:

```zig
b.installArtifact(exe);
```

`b.getInstallStep()` is the handle on that install action; custom steps that need the file to exist should `dependOn` it.

## Running and Passing Args

```zig
const run = b.addRunArtifact(exe);
run.step.dependOn(b.getInstallStep());  // run from the install prefix
if (b.args) |a| run.addArgs(a);         // forward `zig build run -- foo bar`

const run_step = b.step("run", "Run the app");
run_step.dependOn(&run.step);
```

## System Commands

Any external tool can be wired in as a post-build step. Example: compress the installed binary.

```zig
const upx = b.addSystemCommand(&.{ "upx", "--best" });
upx.addArg(b.getInstallPath(.bin, exe.out_filename));
upx.step.dependOn(b.getInstallStep());

const pack_step = b.step("pack", "Build and compress");
pack_step.dependOn(&upx.step);
```

The pattern generalizes: chain the command after `b.getInstallStep()` so the artifact exists, then expose it as a named top-level step.

## Options (build-time flags)

```zig
const strip = b.option(bool, "strip", "Strip the binary") orelse true;
const install_dir = b.option([]const u8, "install-dir", "Install destination") orelse "/usr/local/bin";
_ = strip;
_ = install_dir;
```

`b.option` accepts `bool`, `[]const u8`, `[]const []const u8`, `i64`, and enums. Pass on the CLI as `-Dstrip=false`, `-Dinstall-dir="/opt/bin"`.

## Reading Environment

```zig
const home = b.graph.environ_map.get("HOME") orelse @panic("HOME not set");
const install_dir = b.pathJoin(&.{ home, ".local", "bin" });
```

Do not import `std.process` and try `getEnvVarOwned`; it was removed from the top level.

## Fully Worked Example: CLI with Install-to-PATH

Canonical pattern for a native CLI that builds, installs to `~/.local/bin`, and runs, with `zig build install-local` doing the copy.

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

    const exe = b.addExecutable(.{ .name = "mytool", .root_module = mod });
    b.installArtifact(exe);

    const install_path = b.getInstallPath(.bin, exe.out_filename);

    // install-local: copy the built exe to ~/.local/bin.
    const install_dir = b.option([]const u8, "install-dir",
        "Install destination. Default: $HOME/.local/bin",
    ) orelse blk: {
        const home = b.graph.environ_map.get("HOME") orelse
            @panic("HOME not set; pass -Dinstall-dir=<path>");
        break :blk b.pathJoin(&.{ home, ".local", "bin" });
    };

    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p" });
    mkdir.addArg(install_dir);

    const copy = b.addSystemCommand(&.{ "cp", "-f" });
    copy.addArg(install_path);
    copy.addArg(install_dir);
    copy.step.dependOn(b.getInstallStep());
    copy.step.dependOn(&mkdir.step);

    const install_local = b.step("install-local", "Build and copy to ~/.local/bin");
    install_local.dependOn(&copy.step);

    // run: build then run, forwarding args.
    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    if (b.args) |a| run.addArgs(a);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run.step);
}
```

Invoke:

```bash
zig build --release=small                 # build + install to zig-out/
zig build install-local --release=small   # also copy to ~/.local/bin
zig build run -- --help                   # run, forward args
```

## Custom Install Paths

`b.installArtifact(exe)` defaults to `zig-out/bin/`. For custom placement:

```zig
const install = b.addInstallArtifact(exe, .{
    .dest_dir = .{ .override = .{ .custom = "tools" } },
});
b.getInstallStep().dependOn(&install.step);
```

`InstallDir` values: `.bin`, `.lib`, `.header`, `.prefix`, `.{ .custom = "some/subdir" }`.

## LazyPath

All filesystem paths in build.zig are `LazyPath`. `b.path("src/main.zig")` is the source-relative constructor. `b.getInstallPath(.bin, exe.out_filename)` returns the runtime install path. Use `b.pathJoin(&.{ a, b })` to concatenate strings into a path.

## Dependencies (build.zig.zon)

```zig
// build.zig.zon
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0xabc123def456,
    .minimum_zig_version = "0.16.0",
    .dependencies = .{
        .clap = .{
            .url = "https://github.com/Hejsil/zig-clap/archive/v0.10.0.tar.gz",
            .hash = "122004...",  // run `zig fetch --save` to fill this in
        },
    },
    .paths = .{ "build.zig", "build.zig.zon", "src" },
}
```

Consume in `build.zig`:

```zig
const clap = b.dependency("clap", .{ .target = target, .optimize = optimize });
mod.addImport("clap", clap.module("clap"));
```

Fetch and pin:

```bash
zig fetch --save https://github.com/Hejsil/zig-clap/archive/refs/tags/0.10.0.tar.gz
```

This writes the URL and hash into `build.zig.zon` for you.

## Common Pitfalls

- **Calling `mod.linkSystemLibrary` on `exe` directly** does not exist in 0.16. It is on `*Module`. Do it before `addExecutable`, since executables borrow the module's settings.
- **Forgetting `run.step.dependOn(b.getInstallStep())`** runs the exe out of the build cache rather than the install prefix. Fine for iteration, wrong if you want to validate the installed artifact.
- **Cyclic steps**: `copy.step.dependOn(b.getInstallStep())` is correct. Do not then `b.getInstallStep().dependOn(&copy.step)`; that creates a cycle.
- **Mixing `standardReleaseOptions` (old) and `standardOptimizeOption` (new)**: only the latter exists in 0.16.
- **`b.option` with invalid types**: only `bool`, `i64`, `[]const u8`, `[]const []const u8`, `f64`, and enum types are supported.
