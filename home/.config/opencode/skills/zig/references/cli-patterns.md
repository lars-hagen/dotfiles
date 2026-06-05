# CLI Patterns (Zig 0.16)

Argument parsing, subcommands, exit codes, signal handling, and clean stdout output in a `std.process.Init`-aware `main`.

## The Canonical CLI `main`

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

    if (args.len < 2) {
        try printUsage(out);
        std.process.exit(64); // EX_USAGE
    }

    const cmd = args[1];
    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        try printUsage(out);
        return;
    }
    if (std.mem.eql(u8, cmd, "version") or std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        try out.print("{s}\n", .{VERSION});
        return;
    }
    if (std.mem.eql(u8, cmd, "hash")) {
        return runHash(out, args[2..]);
    }

    try out.print("unknown command: {s}\n", .{cmd});
    std.process.exit(64);
}

fn printUsage(out: *std.Io.Writer) !void {
    try out.print(
        \\mycli {s}
        \\Usage:
        \\  mycli help              Show this help.
        \\  mycli version           Show version.
        \\  mycli hash <input>      Hash input with SHA-256.
        \\
    , .{VERSION});
}

fn runHash(out: *std.Io.Writer, args: []const [:0]const u8) !void {
    if (args.len != 1) {
        try out.print("hash requires exactly one argument\n", .{});
        std.process.exit(64);
    }
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(args[0], &digest, .{});
    try out.print("{x}\n", .{&digest});
}
```

## Argument Iteration Styles

### Slice form (simple)

```zig
const args = try init.minimal.args.toSlice(arena);
// args[0] is the program path.
for (args[1..]) |a| {
    std.debug.print("arg: {s}\n", .{a});
}
```

Good when you need random access or to pass args as a slice to another function.

### Iterator form (lower allocation)

```zig
var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
defer it.deinit();
_ = it.next();  // skip argv[0]
while (it.next()) |a| {
    std.debug.print("arg: {s}\n", .{a});
}
```

Iterator returns `[:0]const u8` - null-terminated, for C interop. On Windows, the iterator converts WTF-16 to WTF-8 on the fly.

### Getopt-style Flag Parsing

Zig stdlib has no built-in getopt. Roll your own for simple cases:

```zig
fn parseFlags(args: []const [:0]const u8) !Flags {
    var f: Flags = .{};
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--verbose")) {
            f.verbose = true;
        } else if (std.mem.eql(u8, a, "--port")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            f.port = try std.fmt.parseInt(u16, args[i], 10);
        } else if (std.mem.startsWith(u8, a, "--port=")) {
            f.port = try std.fmt.parseInt(u16, a["--port=".len..], 10);
        } else if (std.mem.eql(u8, a, "--")) {
            // Positional args start here.
            i += 1;
            f.positional = args[i..];
            break;
        } else if (std.mem.startsWith(u8, a, "-")) {
            return error.UnknownFlag;
        } else {
            f.positional = args[i..];
            break;
        }
    }
    return f;
}

const Flags = struct {
    verbose: bool = false,
    port: u16 = 8080,
    positional: []const [:0]const u8 = &.{},
};
```

### Community libraries

For complex CLIs (many subcommands, auto-help, short+long flags): the `clap` library (Hejsil/zig-clap) is the de facto choice. Add via `zig fetch --save`.

## Exit Codes

```zig
std.process.exit(0);  // success; does NOT run deferred blocks
std.process.exit(1);  // generic failure
std.process.exit(2);  // misuse of shell builtins / CLI
std.process.exit(64); // EX_USAGE per BSD sysexits.h
```

Important: `std.process.exit` calls `_exit` without running `defer` or draining writers. **Flush buffered writers before calling it.**

Cleaner: return errors up from `main`:

```zig
pub fn main(init: std.process.Init) !void {
    doWork(init) catch |err| {
        std.debug.print("error: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}
```

For fatal errors with a formatted message:

```zig
std.process.fatal("config not found: {s}", .{path});
// equivalent to:
//   std.debug.print("config not found: {s}\n", .{path});
//   std.process.exit(1);
```

`std.process.cleanExit(io)` does a cooperative exit that runs atexit handlers.

## Reading stdin

```zig
var in_buf: [4096]u8 = undefined;
var in_fr: Io.File.Reader = .init(.stdin(), init.io, &in_buf);
const in = &in_fr.interface;

// Read lines until EOF. takeDelimiterExclusive returns the slice without the
// trailing '\n'. EOF is treated as a delimiter: the last unterminated line
// is returned normally; only a subsequent call with nothing left to read
// fails with error.EndOfStream.
while (in.takeDelimiterExclusive('\n')) |line| {
    std.debug.print("line: {s}\n", .{line});
} else |err| switch (err) {
    error.EndOfStream => {},
    else => return err,
}
```

Read all stdin to a buffer:

```zig
const all = try in.allocRemaining(gpa, .limited(1 << 24));
defer gpa.free(all);
```

## Detecting Pipe vs TTY

```zig
const stdout = std.Io.File.stdout();
const is_tty = stdout.isTty(init.io) catch false;
if (is_tty) {
    try out.print("\x1b[32mok\x1b[0m\n", .{});
} else {
    try out.print("ok\n", .{});
}
```

For colored output, gate ANSI escapes on `is_tty` and `NO_COLOR` env var:

```zig
const no_color = init.environ_map.get("NO_COLOR") != null;
const use_color = is_tty and !no_color;
```

## Signal Handling

On POSIX, install handlers via `std.posix.sigaction`. On Windows, use `SetConsoleCtrlHandler`. There is no portable cross-platform signal API in std as of 0.16; you wire it per platform.

For Ctrl+C specifically, setting a flag and checking it in your main loop is the portable pattern:

```zig
// Cross-platform Ctrl+C. Requires your own platform-specific registration.
var should_stop: std.atomic.Value(u32) = std.atomic.Value(u32).init(0);

// In your main loop:
while (should_stop.load(.seq_cst) == 0) {
    // work
}
```

Windows-specific registration:

```zig
extern "kernel32" fn SetConsoleCtrlHandler(
    handler: ?*const fn (u32) callconv(.winapi) i32,
    add: i32,
) callconv(.winapi) i32;

fn ctrlHandler(_: u32) callconv(.winapi) i32 {
    should_stop.store(1, .seq_cst);
    return 1; // handled
}

_ = SetConsoleCtrlHandler(&ctrlHandler, 1);
```

## Environment Variables

```zig
// Non-owning, fast read:
const home = init.environ_map.get("HOME") orelse "/";

// Owning (allocates):
const path = try init.minimal.environ.getAlloc(gpa, "PATH");
defer gpa.free(path);

// Iteration:
var it = init.environ_map.iterator();
while (it.next()) |entry| {
    std.debug.print("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
}
```

## Running Subcommands

```zig
const res = try std.process.run(gpa, init.io, .{
    .argv = &.{ "git", "rev-parse", "--short", "HEAD" },
});
defer gpa.free(res.stdout);
defer gpa.free(res.stderr);

if (res.term != .Exited or res.term.Exited != 0) {
    return error.GitFailed;
}

const sha = std.mem.trim(u8, res.stdout, "\r\n ");
try out.print("HEAD: {s}\n", .{sha});
```

## Wiring `b.args` for `zig build run -- ...`

```zig
// build.zig
const run = b.addRunArtifact(exe);
if (b.args) |a| run.addArgs(a);

const run_step = b.step("run", "Run the app");
run_step.dependOn(&run.step);
```

Then `zig build run -- --port 9000 --verbose` forwards `--port 9000 --verbose` into the executable.

## Help Text Conventions

Conventional exit codes:

- `0` - success
- `1` - generic failure (the program ran but failed)
- `2` - command line misuse (often `64` per sysexits)
- Nonzero from signals: `128 + signal_number` on POSIX

Conventional flags:

- `-h`, `--help` - usage
- `-v`, `--version` - version
- `--` - end of options (positional args follow)
- Long flags accept `--flag value` and `--flag=value`.
- Short flags can be bundled: `-abc` = `-a -b -c` (you have to implement this).

## Common Mistakes

- **`std.process.exit` before flushing stdout**: last bytes lost. Always `out.flush()` first or wrap via an error-returning `main`.
- **Comparing `[:0]const u8` args with `== "foo"`**: strings are slices; use `std.mem.eql(u8, a, "foo")`.
- **Allocating args with `init.gpa` but forgetting to free**: use `arena` for args; the whole arena is freed on process exit automatically.
- **Writing directly to the underlying `File`**: bypasses buffering, slower. Use `Io.File.Writer.interface`.
- **Assuming `argv[0]` is the program name**: on Windows it is the full path; on POSIX it is whatever the parent set it to. For resolving the actual executable, use `std.process.executablePathAlloc(init.io, gpa)`.
