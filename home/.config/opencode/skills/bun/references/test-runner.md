# Bun Test Runner

Complete reference for `bun test` in v1.3.14. Jest-compatible API with Bun-specific enhancements.

## Flags Cheatsheet

| Flag                                 | Purpose                                                                  |
| ------------------------------------ | ------------------------------------------------------------------------ |
| `--timeout=<ms>`                     | Per-test timeout. Default 5000.                                          |
| `-u` / `--update-snapshots`          | Update `.snap` and inline snapshots.                                     |
| `--rerun-each=<n>`                   | Re-run every test file N times. Helps catch flakes.                      |
| `--retry=<n>`                        | Default retry count; override per-test with `{ retry: N }`.              |
| `--todo`                             | Include `test.todo()` entries in the run.                                |
| `--only`                             | Only run tests marked `test.only()` / `describe.only()`.                 |
| `--pass-with-no-tests`               | Exit 0 when no tests match. Useful in monorepos with optional test dirs. |
| `--concurrent`                       | Treat every test as `test.concurrent()`.                                 |
| `--max-concurrency=<n>`              | Cap concurrent tests. Default 20.                                        |
| `--randomize`                        | Run tests in random order. Seed printed in summary.                      |
| `--seed=<n>`                         | Reproduce a randomized run. Implies `--randomize`.                       |
| `--coverage`                         | Emit coverage profile.                                                   |
| `--coverage-reporter=<val>`          | `text`, `lcov`, or both. Default `text`.                                 |
| `--coverage-dir=<path>`              | Coverage output directory. Default `coverage`.                           |
| `--bail[=<n>]`                       | Exit after N failures. Default 1 if flag given without value.            |
| `-t` / `--test-name-pattern=<regex>` | Filter by test name.                                                     |
| `--reporter=<val>`                   | `junit` (requires `--reporter-outfile`), `dots`, or default console.     |
| `--reporter-outfile=<path>`          | Output path for `--reporter=junit`.                                      |
| `--dots`                             | Shortcut for `--reporter=dots`.                                          |
| `--only-failures`                    | Hide passing tests in output.                                            |
| `--path-ignore-patterns=<glob>`      | Skip matching test files.                                                |
| `--changed[=<ref>]`                  | Only run test files affected by changes vs git HEAD or given ref.        |
| `--isolate`                          | Each test file in a fresh global object.                                 |
| `--parallel=<n>`                     | Run files in N worker processes. Implies `--isolate`. Default CPU count. |
| `--parallel-delay=<ms>`              | Delay before spawning workers after the first. Default 5.                |
| `--shard=<m>/<n>`                    | Run shard M of N. For splitting tests across CI jobs.                    |

## High-Value Flags

### `--changed` (git-aware test selection)

Only runs test files affected by changed source files according to git.

```bash
bun test --changed              # vs HEAD
bun test --changed=main         # vs main branch
bun test --changed=HEAD~3       # vs three commits ago
```

Massive iteration-speed win in monorepos and pre-commit hooks.

### `--parallel` and `--isolate`

`--parallel=N` runs test files in N separate worker processes. Each gets a fresh global object, so leaked handles or globals from one file cannot affect another.

```bash
bun test --parallel=4           # four workers
bun test --parallel=0           # auto-detect CPU count (omit or 0)
bun test --isolate              # isolation without spawning workers
```

Use `--parallel` when tests touch file system, databases, or shared caches. Use `--isolate` alone when tests are CPU-light but leak globals (timers, event listeners, modules with side effects).

### `--shard` for CI fan-out

```bash
# Across 4 CI jobs:
bun test --shard=1/4
bun test --shard=2/4
bun test --shard=3/4
bun test --shard=4/4
```

Works with `--parallel` and `--randomize` together.

### `--rerun-each` and `--retry`

Distinct purposes.

- `--rerun-each=N`: Runs every test N times. Tool for finding flakes. If any run fails, the test fails.
- `--retry=N`: Allows a failing test up to N retries before marking it failed. Tolerates flakes. Combine with per-test `{ retry: 0 }` to disable retries on deterministic tests.

### `--randomize` + `--seed`

Shuffles test order within a file. Exposes hidden coupling between tests (shared state, leaked globals).

```bash
bun test --randomize
# --seed=1042198372 printed in summary
bun test --seed 1042198372      # reproduce the run
```

### JUnit reporter

```bash
bun test --reporter=junit --reporter-outfile=./test-results.xml
```

Upload the file as a CI artifact; GitHub Actions, Azure Pipelines, and GitLab all parse it.

## Writing Tests

### Import surface

```ts
import {
  test,
  it,
  expect,
  describe,
  beforeAll,
  afterAll,
  beforeEach,
  afterEach,
  mock,
  spyOn,
  expectTypeOf,
  setSystemTime,
} from "bun:test";
```

`it` is an alias for `test`. `setSystemTime` controls the clock inside tests.

### Modifiers and chaining

Modifiers can be chained in any order.

```ts
test.skip("not ready", () => {});
test.only("focused", () => {});
test.todo("write this later");
test.failing("known bug", () => {
  throw new Error("expected");
});
test.serial("must run sequentially", () => {});

describe.concurrent("parallel group", () => {
  test("a", async () => {
    /* ... */
  });
  test("b", async () => {
    /* ... */
  });
});

test.failing.each([1, 2, 3])("case %i", (n) => {
  throw new Error("WIP");
});
test.skip.each([["a"], ["b"]])("skipped $0", () => {});
```

`test.failing()` flips pass/fail: the test passes when it throws, fails when it succeeds. Signal that a known bug exists or that TDD is in progress.

Use `test.failing()` only for a tracked bug (with an issue link in a comment) or TDD where the fix is imminent. Do not use it to silence flakes; use `--retry` or fix the flake. Review `test.failing` entries in code review. A PR that adds `.failing` to silence a real regression is a common attack path against test hygiene.

`test.serial()` opts back into sequential execution inside a `describe.concurrent()` block.

### Concurrent execution in code

Mark individual tests or entire describes as concurrent without a CLI flag.

```ts
test.concurrent("fetches user A", async () => {
  /* ... */
});
describe.concurrent("HTTP endpoints", () => {
  /* all tests parallel */
});
```

Concurrent limitations (apply regardless of how concurrency was enabled):

- `expect.assertions()` and `expect.hasAssertions()` not supported.
- `toMatchSnapshot()` not supported. `toMatchInlineSnapshot()` works.
- `beforeAll` / `afterAll` hooks run sequentially.

Glob-based concurrent selection in `bunfig.toml`:

```toml
[test]
concurrentTestGlob = "**/integration/**/*.test.ts"
```

### Timeouts and retries per-test

```ts
test("slow operation", async () => {
  /* ... */
}, 10000); // 10s timeout
test("with retries", { retry: 3 }, async () => {
  /* ... */
});
test("both", { timeout: 10000, retry: 3 }, async () => {
  /* ... */
});
```

## Matchers Added in 1.3

### Return-value matchers

```ts
const fn = mock(() => 42);
fn();
fn();

expect(fn).toHaveReturnedWith(42);
expect(fn).toHaveLastReturnedWith(42);
expect(fn).toHaveNthReturnedWith(1, 42);
```

### Type-level matchers with `expectTypeOf`

Type assertions verified by `tsc`, not at runtime.

```ts
import { expectTypeOf, test } from "bun:test";

test("response shape", () => {
  expectTypeOf<{ id: string; name: string }>().toHaveProperty("id");
  expectTypeOf<Promise<number>>().resolves.toBeNumber();
  expectTypeOf<string | number>().toEqualTypeOf<string | number>();
});
```

Run `bunx tsc --noEmit` to verify type assertions as part of CI.

### Inline snapshot indentation

`toMatchInlineSnapshot()` now auto-indents to match surrounding code, like Jest.

```ts
expect(user).toMatchInlineSnapshot(`
  {
    "name": "Alice",
    "age": 30,
  }
`);
```

## Mocking

### `mock()` and `spyOn()`

```ts
import { mock, spyOn } from "bun:test";

const fn = mock((x: number) => x * 2);
fn(5);
expect(fn).toHaveBeenCalledWith(5);
expect(fn.mock.results[0].value).toBe(10);

const obj = { greet: () => "hello" };
const spy = spyOn(obj, "greet").mockReturnValue("mocked");
expect(obj.greet()).toBe("mocked");
```

### `mock.module()` for module-level mocks

```ts
import { mock } from "bun:test";

mock.module("./database", () => ({
  query: mock(() => [{ id: 1, name: "Alice" }]),
}));
```

### `mock.clearAllMocks()`

```ts
import { mock } from "bun:test";
afterEach(() => {
  mock.clearAllMocks();
});
```

## Time Control

```ts
import { setSystemTime, test } from "bun:test";

test("uses fake date", () => {
  setSystemTime(new Date("2024-01-01T00:00:00Z"));
  expect(Date.now()).toBe(1704067200000);
  setSystemTime(); // reset
});
```

Interacts with `Date`, `setTimeout`, `setInterval`, and `performance.now()` depending on configuration. See the mock-clock guide for edge cases.

## Coverage

### Basic usage

```bash
bun test --coverage
bun test --coverage --coverage-reporter=lcov
bun test --coverage --coverage-reporter=text --coverage-reporter=lcov
```

### `bunfig.toml` options

```toml
[test]
coverageThreshold = 0.8               # fail if below 80 percent
coveragePathIgnorePatterns = [
  "**/node_modules/**",
  "**/*.generated.ts",
]
coverageSkipTestFiles = true          # do not include test files themselves
```

Per-file thresholds are supported via an object form:

```toml
[test]
coverageThreshold = { lines = 0.8, functions = 0.9, statements = 0.85 }
```

## CI Strictness

In CI environments (`CI=true`), `bun test` enforces extra safety:

- Fails if a file contains `test.only()`. Prevents accidental focused tests in merged PRs.
- Fails if a snapshot test would create a new snapshot without `--update-snapshots`. Prevents surprise snapshot additions.

Opt out for local debugging with `CI=false bun test`.

## Discovery

Default patterns:

- `*.test.{js,jsx,ts,tsx}`
- `*_test.{js,jsx,ts,tsx}`
- `*.spec.{js,jsx,ts,tsx}`
- `*_spec.{js,jsx,ts,tsx}`
- Files inside `__tests__/` directories

Override with `bunfig.toml`:

```toml
[test]
root = "./tests"
preload = ["./tests/setup.ts"]
```

Positional arguments filter further: `bun test auth billing` runs only files whose paths contain those strings.

## Async Stack Traces

v1.3 added proper async stack trace preservation across `await` boundaries. Error reports now include the full async call chain, making `bun test` output significantly more useful for debugging async failures. No configuration needed.

## Watch Mode

```bash
bun test --watch
```

Re-runs affected test files on change. Combines well with `--changed` if you only want tests affected by in-flight git changes.

## Things `bun test` Does Not Cover

- Browser DOM testing requires `happy-dom` as a dependency. See `bun add -d @happy-dom/global-registrator`.
- React component tests need `@testing-library/react` as usual. Works inside Bun via the happy-dom bootstrap.
- Full Jest plugin ecosystem is not available. Most popular matchers and most of the Jest API surface works; exotic plugins often do not.

## v1.3.14 Compatibility Fix

The top-level `node:test` `test()` entry point now honors `{ skip }` and `{ todo }` options. Nested `Suite#test` already honored them.
