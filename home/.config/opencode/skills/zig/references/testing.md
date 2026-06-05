# Testing (Zig 0.16)

`zig test` and `zig build test` run `test "name" { ... }` blocks. Tests are first-class: no framework, no discovery config, no runner package.

## Writing Tests

Tests live alongside code in the same `.zig` file:

```zig
const std = @import("std");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "add works" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
}

test "add negatives" {
    try std.testing.expect(add(-1, -1) == -2);
}
```

Test blocks are only compiled when the file is used as a test root (via `zig test foo.zig` or via `b.addTest(.{ .root_module = mod })`).

## Test Assertions

```zig
const testing = std.testing;

try testing.expect(condition);                 // bool
try testing.expectEqual(expected, actual);     // any equality
try testing.expectEqualStrings("a", s);        // []const u8
try testing.expectEqualSlices(T, a, b);
try testing.expectEqualDeep(a, b);             // recursive deep equality
try testing.expectApproxEqAbs(1.0, x, 0.01);   // floats
try testing.expectApproxEqRel(1.0, x, 0.001);
try testing.expectError(error.BadInput, parse("x"));
try testing.expectFmt("x=42", "x={d}", .{42});
```

## `std.testing.allocator`

Provides a leak-checking allocator that fails the test if any allocation is not freed.

```zig
test "array list" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    try list.appendSlice(gpa, "hello");
    try std.testing.expectEqualStrings("hello", list.items);
}
```

Forgetting the `defer list.deinit(gpa)` fails the test with a leak stacktrace.

## Running Tests

```bash
# Run every test in one file:
zig test src/foo.zig

# Run a subset by name (regex-like substring):
zig test src/foo.zig --test-filter "parse"

# Run tests for an entire module via build.zig:
zig build test

# With filters plumbed through your build.zig:
zig build test -Dtest-filter="parse"
```

A `build.zig` with filter support:

```zig
const test_filter = b.option([]const u8, "test-filter", "Filter tests by substring");
const tests = b.addTest(.{
    .root_module = mod,
    .filters = if (test_filter) |f| &.{f} else &.{},
});
const run_tests = b.addRunArtifact(tests);
const test_step = b.step("test", "Run tests");
test_step.dependOn(&run_tests.step);
```

## Skipping Tests

```zig
test "platform specific" {
    if (@import("builtin").os.tag != .linux) return error.SkipZigTest;
    // ...
}
```

`error.SkipZigTest` is a sentinel the test runner treats as "skipped" rather than "failed".

## Fuzz Tests

0.16 ships `std.testing.fuzz`. The Zig fuzzer discovers inputs that cause different code paths.

```zig
test "fuzz parser" {
    try std.testing.fuzz({}, fuzzOne, .{});
}

fn fuzzOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    const gpa = std.testing.allocator;

    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    while (!smith.eos()) {
        const n = smith.value(u8);
        try buf.append(gpa, n);
    }

    // Exercise parser against the fuzzer-chosen buffer.
    _ = parse(buf.items) catch {};
}
```

Run:

```bash
zig build test --fuzz
```

The fuzzer runs until you interrupt it; it writes crashing inputs to the cache for reproduction.

## Test-only Code via `@import("builtin").is_test`

```zig
pub fn debugLog(msg: []const u8) void {
    if (@import("builtin").is_test) {
        // Tests: never write to stderr.
        return;
    }
    std.debug.print("{s}\n", .{msg});
}
```

## Reference Decls

If a file's declarations are all private and tests do not reference them, they will not be compiled. To force test compilation of everything in a file:

```zig
test {
    std.testing.refAllDecls(@This());
}
```

This pulls every `pub`/`const`/`fn` in the file into the test compilation, catching compile errors in otherwise unreferenced code.

For a deeper variant that also compiles decls in imported files, recurse manually:

```zig
test {
    @setEvalBranchQuota(10_000);
    std.testing.refAllDecls(@This());
    inline for (.{ @import("parser.zig"), @import("lexer.zig") }) |sub| {
        std.testing.refAllDecls(sub);
    }
}
```

The earlier `std.testing.refAllDeclsRecursive` helper is gone in 0.16.

## Test Organization

Common pattern: a top-level `tests.zig` that imports every file with tests, so `zig build test` runs them all:

```zig
// src/tests.zig
comptime {
    _ = @import("parser.zig");
    _ = @import("lexer.zig");
    _ = @import("vm.zig");
}

test {
    std.testing.refAllDecls(@This());
}
```

```zig
// build.zig
const tests_mod = b.createModule(.{
    .root_source_file = b.path("src/tests.zig"),
    .target = target,
    .optimize = optimize,
});
const tests = b.addTest(.{ .root_module = tests_mod });
```

## Benchmarks

No built-in benchmark runner, but you can use tests with `std.Io.Clock.now`:

```zig
test "bench hash" {
    const io = std.testing.io;
    const t0 = std.Io.Clock.now(.awake, io);
    var i: usize = 0;
    while (i < 1_000_000) : (i += 1) {
        _ = std.hash.Wyhash.hash(0, "some data to hash");
    }
    const t1 = std.Io.Clock.now(.awake, io);
    std.debug.print("elapsed: {f}\n", .{t0.durationTo(t1)});
}
```

Run only this test:

```bash
zig test src/foo.zig --test-filter "bench hash"
```

Bench in release mode to avoid Debug overhead:

```bash
zig test src/foo.zig -O ReleaseFast --test-filter "bench"
```

## CI Recipe

GitHub Actions example:

```yaml
- uses: goto-bus-stop/setup-zig@v2
  with:
    version: 0.16.0
- run: zig build test --summary all
- run: zig build --release=small
- run: zig fmt --check src build.zig
```

`zig fmt --check` returns non-zero on unformatted files, suitable as a lint gate.

## Common Mistakes

- **Forgetting `try`** on `testing.expect*` calls. They return errors; bare calls are compile errors.
- **Using `std.testing.allocator` outside a test block.** It panics in non-test builds.
- **Relying on test order.** Zig runs tests in declaration order within a file but across files is implementation-defined. Make each test hermetic.
- **Not freeing in tests.** Use `defer ...deinit(gpa)` religiously; `std.testing.allocator` will catch leaks.
- **Reaching for a recursive `refAllDecls`.** 0.16 dropped `refAllDeclsRecursive`. If you need to force-compile imported modules' decls, recurse explicitly with `inline for` over `@import(...)` results.
