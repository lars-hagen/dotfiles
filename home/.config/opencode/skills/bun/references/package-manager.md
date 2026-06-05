# Bun Package Manager

Complete reference for `bun install`, `bun add`, `bun pm`, and related commands in v1.3.14.

## Core Commands

| Command                             | Purpose                                               |
| ----------------------------------- | ----------------------------------------------------- |
| `bun install` / `bun i`             | Install dependencies from `package.json`.             |
| `bun add <pkg>` / `bun a <pkg>`     | Add a dependency.                                     |
| `bun remove <pkg>` / `bun rm <pkg>` | Remove a dependency.                                  |
| `bun update [<pkg>]`                | Update dependencies.                                  |
| `bun outdated`                      | List dependencies with newer versions available.      |
| `bun audit`                         | Scan dependencies for known CVEs.                     |
| `bun why <pkg>`                     | Explain why a package is installed.                   |
| `bun info <pkg>`                    | Show npm registry metadata.                           |
| `bun link` / `bun unlink`           | Cross-project package linking.                        |
| `bun publish`                       | Publish to npm.                                       |
| `bun patch <pkg>`                   | Git-friendly package patching.                        |
| `bun pm <subcommand>`               | Utility subcommands (pack, version, pkg, cache, ...). |

## `bun install`

### Useful flags

| Flag                   | Purpose                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| `--production`         | Skip `devDependencies`.                                            |
| `--frozen-lockfile`    | Fail if `bun.lock` is out of sync. Use in CI.                      |
| `--lockfile-only`      | Update the lockfile without fetching tarballs.                     |
| `--save-text-lockfile` | Write human-readable `bun.lock` (default now).                     |
| `--linker=hoisted`     | Opt out of isolated installs (see below).                          |
| `--linker=isolated`    | Force isolated installs.                                           |
| `--no-save`            | Do not modify `package.json`.                                      |
| `--dry-run`            | Show what would be installed, do nothing.                          |
| `--trust`              | Pre-trust lifecycle scripts for specific packages.                 |
| `--analyze`            | Scan your code for imports not in `package.json` and install them. |
| `--cpu=<arch>`         | Filter optional dependencies by architecture.                      |
| `--os=<os>`            | Filter optional dependencies by OS.                                |
| `--verbose`            | Print resolution details.                                          |

### `--analyze`

Scans source files for `import` and `require` calls and installs packages that are imported but missing from `package.json`. Useful for codebases that drifted or for fast migration.

```bash
bun install --analyze
```

**Supply-chain risk. Never run `--analyze` on code you did not write or have not reviewed.** An attacker-seeded or hallucinated import line will be fetched from npm. Lifecycle scripts are disabled by default, but the package's first-`import` code still executes. In CI and production, use `bun install --frozen-lockfile` and never `--analyze`. Combine with `minimumReleaseAge` and the Security Scanner API (below) to harden the install path.

### Platform filtering

```bash
bun install --os linux --cpu arm64
bun install --os darwin --os linux --cpu x64
bun install --os '*' --cpu '*'
```

Controls which `optionalDependencies` get installed. Useful when building Docker images for a target platform on a developer machine of a different platform.

## `bun add`

```bash
bun add express                        # dependency
bun add -d typescript                  # devDependency
bun add -D @types/node                 # also devDependency
bun add --optional sharp               # optionalDependency
bun add --peer react                   # peerDependency
bun add -g <pkg>                       # global install
bun add lodash@4.17.21                 # pinned version
bun add react@latest
bun add react@next
bun add github:user/repo               # from GitHub
bun add git+https://github.com/u/r.git # from git URL
bun add file:./local-package           # from local path
bun add https://example.com/pkg.tgz    # tarball
bun add pkg@npm:other-pkg@1.2.3        # npm alias
```

## Lockfile

### `bun.lock` is text (v1.3 default)

Human-readable, git-mergeable. Older versions used binary `bun.lockb`. Both are still understood, but `bun.lock` is the default for new installs.

To generate a yarn-compatible lockfile for interoperability:

```bash
bun install --yarn                     # produces yarn.lock
```

### Automatic migration

When running `bun install` in a project with an existing `yarn.lock` or `pnpm-lock.yaml`, Bun migrates the dependency tree while preserving the resolved versions. No manual steps needed.

## Isolated Installs (default for workspaces)

Each workspace package only sees dependencies it declares in its own `package.json`, preventing "phantom dependencies" where code accidentally relied on a transitive install.

```bash
bun install                   # isolated by default in workspaces
bun install --linker=hoisted  # opt out; classic npm/Yarn flat layout
```

Also configurable per project in `bunfig.toml`:

```toml
[install]
linker = "isolated"   # or "hoisted"
```

See `bun.com/docs/pm/isolated-installs` for the full mechanism.

## Catalogs

Centralize dependency versions across workspace packages. Define once, reference everywhere.

Root `package.json`:

```json
{
  "workspaces": ["packages/*"],
  "catalog": {
    "react": "^18.0.0",
    "typescript": "^5.0.0"
  },
  "catalogs": {
    "react19": { "react": "^19.0.0" }
  }
}
```

Workspace `package.json` referencing the root `catalog`:

```json
{
  "dependencies": {
    "react": "catalog:",
    "typescript": "catalog:"
  }
}
```

Workspace `package.json` referencing a named catalog:

```json
{
  "dependencies": {
    "react": "catalog:react19"
  }
}
```

Inspired by pnpm catalogs. `bun outdated` and `bun update -i` understand catalog references natively.

## Global Virtual Store

Packages are installed once globally and symlinked into each project's `node_modules`. Similar to pnpm's content-addressable store. Massive disk savings across many projects.

In v1.3.14, `bun install --linker=isolated` can use a shared global virtual store. Warm installs with a present lockfile, warm cache, and wiped `node_modules` can become much faster because project-local `node_modules/.bun/<pkg>@<ver>` entries are symlinks into global `<cache>/links/` entries instead of per-project file copies.

This is experimental and off by default.

Configuration lives in `bunfig.toml`:

```toml
[install]
globalStore = true
```

Or enable per command:

```bash
BUN_INSTALL_GLOBAL_STORE=1 bun install
```

A package is eligible only when it comes from an immutable cache source such as the npm registry, git, or tarball; is unpatched; has no trusted lifecycle scripts; and its transitive dependency closure is also eligible. Ineligible packages automatically fall back to per-project copies.

v1.3.14 also synthesizes an implicit `"*"` optional peer dependency for entries present in `peerDependenciesMeta` but missing from `peerDependencies`, matching pnpm/yarn behavior.

See `bun.com/docs/pm/global-store`.

## Workspaces

Basic layout:

```json
{
  "name": "monorepo",
  "workspaces": ["packages/*", "apps/*"]
}
```

### `--filter` for targeted operations

```bash
bun run --filter '@myapp/*' build         # glob matches scope
bun run --filter 'api' test
bun update -i --filter '@myapp/frontend'
bun outdated --recursive
```

Glob patterns match workspace names. Use `--recursive` to run across all workspaces.

### `linkWorkspacePackages`

```toml
[install]
linkWorkspacePackages = false
```

When `false`, workspace dependencies install from the registry instead of linking locally. Useful in CI where prebuilt packages are faster than building from source.

## Interactive Updates

```bash
bun update -i                            # interactive picker
bun update -i --latest                   # ignore semver ranges, pick latest
bun update -i --recursive                # across all workspaces
bun update -i --filter '@myapp/backend'  # scoped to a workspace
```

Arrow keys to navigate, space to select, enter to confirm. Shows current, target (respecting ranges), and latest for each package.

## `bun outdated`

```bash
bun outdated                             # current project
bun outdated --recursive                 # all workspaces
bun outdated --filter '@myapp/backend'
```

Output includes a Workspace column in recursive mode. Catalog entries appear with `catalog:` label.

## `bun why`

Explains the dependency chain that pulled a package into `node_modules`.

```bash
bun why tailwindcss
# tailwindcss@3.4.17
#   └─ peer @tailwindcss/typography@0.5.16 (requires >=3.0.0 ...)
```

Essential for debugging "why is this in my bundle" questions.

## `bun info`

```bash
bun info react
bun info react@18.2.0
bun info react dist-tags
```

Shows versions, `dist-tags`, maintainers, dependencies, and publish metadata. Faster than `npm view`.

## `bun audit`

Uses the same advisory database as `npm audit`.

```bash
bun audit
bun audit --severity=high
bun audit --json > report.json
```

Run in CI to fail builds on high-severity vulnerabilities.

## Security Scanner API

Plug in third-party scanners (Socket, Snyk, enterprise internal tools) that run during `bun install`, `bun add`, and friends. Scanners can block installation entirely on `fatal` severity.

```bash
bun add -d @socketsecurity/bun-security-scanner
```

```toml
[install.security]
scanner = "@socketsecurity/bun-security-scanner"
```

Severity levels:

- `fatal`: Installation stops, non-zero exit code.
- `warn`: Interactive terminals prompt to continue; CI exits immediately.

Scanners can read environment variables for authentication, e.g. `SECURITY_API_KEY`. See the official template at `github.com/oven-sh/security-scanner-template` for writing a custom scanner.

## `minimumReleaseAge`

Supply-chain defense. Require packages to have been published for N seconds before they can be installed. Protects against "just-published and yanked" malicious packages.

```toml
[install]
minimumReleaseAge = 604800    # 7 days in seconds
```

## Trusted Dependencies

Some packages run install/postinstall scripts. Bun does not run them by default. To allow scripts for a specific package:

```json
{
  "trustedDependencies": ["sharp", "esbuild"]
}
```

Or use `bun install --trust <pkg>` to trust and install in one step.

## `bun pm` Subcommands

| Subcommand                      | Purpose                                    |
| ------------------------------- | ------------------------------------------ |
| `bun pm pack`                   | Create a tarball (like `npm pack`).        |
| `bun pm pack --filename <path>` | Custom output name.                        |
| `bun pm pack --quiet`           | Scripting mode.                            |
| `bun pm version <bump>`         | Bump version with pre/post scripts.        |
| `bun pm pkg get <path>`         | Read a value from `package.json`.          |
| `bun pm pkg set <key>=<val>`    | Write a value.                             |
| `bun pm pkg delete <key>`       | Remove a key.                              |
| `bun pm pkg fix`                | Normalize `package.json`.                  |
| `bun pm bin`                    | Print the node_modules/.bin directory.     |
| `bun pm ls`                     | List installed packages.                   |
| `bun pm ls --all`               | Full tree.                                 |
| `bun pm cache`                  | Print cache directory.                     |
| `bun pm cache rm`               | Clear the global cache.                    |
| `bun pm trust <pkg>`            | Trust a package's install scripts.         |
| `bun pm untrusted`              | List packages with unrun install scripts.  |
| `bun pm migrate`                | Migrate `package-lock.json` to `bun.lock`. |
| `bun pm hash`                   | Print the lockfile hash.                   |
| `bun pm whoami`                 | Print the authenticated npm user.          |
| `bun pm default-trusted`        | Print packages trusted by default.         |

### `bun pm version`

```bash
bun pm version patch                   # 1.2.3 -> 1.2.4
bun pm version minor                   # 1.2.3 -> 1.3.0
bun pm version major                   # 1.2.3 -> 2.0.0
bun pm version premajor --preid=beta   # 1.2.3 -> 2.0.0-beta.0
bun pm version 1.5.0                   # explicit
```

Runs `preversion`, `version`, and `postversion` scripts from `package.json` just like npm.

### `bun pm pkg`

Scriptable `package.json` edits without manual JSON manipulation.

```bash
bun pm pkg get name version
bun pm pkg set scripts.test="bun test"
bun pm pkg set 'repository.type'=git 'repository.url'=https://github.com/org/repo
bun pm pkg delete scripts.postinstall
bun pm pkg fix                         # canonicalize fields
```

## `bun link`

Register the current package globally, then link it into other projects.

```bash
cd ~/projects/my-lib
bun link                               # registers

cd ~/projects/consumer
bun link my-lib                        # links the registered version
```

`bun unlink` in the library directory deregisters.

## `bun publish`

Supports npm's publish semantics plus provenance.

```bash
bun publish
bun publish --access public
bun publish --tag beta
bun publish --dry-run
bun publish --otp <code>
```

Works with any npm-compatible registry including JFrog Artifactory, Azure Artifacts, and self-hosted Verdaccio.

v1.3.14 sends README metadata to the registry, matching `npm publish`. Bun finds the first `README` or `README.*` file case-insensitively in the workspace and includes it in the version metadata for workspace and tarball publishes. A `readme` field already present in `package.json` takes precedence.

## `bun patch`

Git-friendly patching of `node_modules` packages.

```bash
bun patch left-pad
# Bun prints the editable directory.
# Edit files there, then:
bun patch --commit left-pad
```

Produces a `.patch` file that Bun reapplies on subsequent installs. Replaces `patch-package` with a native, reproducible workflow.

## Registries and Scopes

Configure registries in `bunfig.toml`:

```toml
[install.scopes]
"@myorg" = { url = "https://npm.pkg.github.com", token = "$GITHUB_TOKEN" }
"@internal" = { url = "https://artifactory.example.com/api/npm/npm-local", username = "$ART_USER", password = "$ART_PASS" }

[install]
registry = "https://registry.npmjs.org"
```

`.npmrc` files are also respected. See `bun.com/docs/pm/npmrc`.

## Overrides and Resolutions

Force specific versions across the tree, useful for security patches or conflict resolution.

```json
{
  "overrides": {
    "lodash": "4.17.21",
    "axios": "^1.0.0"
  }
}
```

Yarn-style `resolutions` also works. Bun reads both.

## `bunfig.toml` Install Section

```toml
[install]
registry = "https://registry.npmjs.org"
production = false
optional = true
dev = true
peer = true
exact = false                          # save with ^ ranges by default
saveTextLockfile = true                # default in 1.3+
globalDir = "~/.bun/install/global"
globalBinDir = "~/.bun/bin"
cache = "~/.bun/install/cache"
linker = "isolated"                    # or "hoisted"
linkWorkspacePackages = true
minimumReleaseAge = 0
concurrentScripts = 5
frozenLockfile = false

[install.security]
scanner = "@socketsecurity/bun-security-scanner"

[install.scopes]
"@myorg" = { url = "...", token = "..." }
```

## Production Install Checklist

For CI and container builds:

```bash
bun install --frozen-lockfile --production
```

- `--frozen-lockfile` errors if the lockfile is out of date. No silent drift.
- `--production` skips devDependencies. Smaller image, faster install.
- Combine with `--no-install` when running the built app so missing dependencies surface as errors, not silent auto-installs.
