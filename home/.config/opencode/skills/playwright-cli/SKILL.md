---
name: playwright-cli
description: Automate browser interactions, test web pages and work with Playwright tests.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Browser Automation with playwright-cli

## Quick start

```bash
# open new browser
playwright-cli open
# navigate to a page
playwright-cli goto https://playwright.dev
# interact with the page using refs from the snapshot
playwright-cli click e15
playwright-cli type "page.click"
playwright-cli press Enter
# take a screenshot (rarely used, as snapshot is more common)
playwright-cli screenshot
# close the browser
playwright-cli close
```

## Machine defaults

The global `~/.playwright/cli.config.json` applies to every session (no flag
needed): real headless Chrome with a fixed viewport/UA and
`--disable-blink-features=AutomationControlled`. In testing this passed the
rebrowser bot-detection checks and let Cloudflare Turnstile auto-solve in headless.
It also loads `~/.config/playwright-auth/all-sites.json`, so captured sites start
logged in with no `state-load`. For a logged-out session, set
`PLAYWRIGHT_MCP_STORAGE_STATE` to `~/.config/playwright-auth/empty.json` (or another
profile) on `open`; an empty string is ignored, it must be a real state file.

To preserve stealth:
- Avoid `eval`/`run-code` on fingerprinting pages; their main-world execution is
  detectable. `goto`, `click`, `fill`, `snapshot`, and `find` are isolated-world safe.
- Keep launch args minimal; flags like `--disable-gpu` can break Turnstile autosolve.
- `--headed` overrides the headless default.
- Inspect the merged config with `playwright-cli config-print`.

## Commands

### Core

```bash
playwright-cli open
# open and navigate right away
playwright-cli open https://example.com/
playwright-cli goto https://playwright.dev
playwright-cli type "search query"
playwright-cli click e3
playwright-cli dblclick e7
# --submit presses Enter after filling the element
playwright-cli fill e5 "user@example.com"  --submit
playwright-cli drag e2 e8
# drop files or data onto an element (from outside the page)
playwright-cli drop e4 --path=./image.png
playwright-cli drop e4 --data="text/plain=hello world"
playwright-cli hover e4
playwright-cli select e9 "option-value"
playwright-cli upload ./document.pdf
playwright-cli check e12
playwright-cli uncheck e12
playwright-cli snapshot
# search the snapshot for text or a regexp, returns matching nodes with surrounding context
playwright-cli find "Sign in"
playwright-cli find --regex "Sign (in|up)"
# wrap the regexp in slashes to add flags, e.g. /i for case-insensitive
playwright-cli find --regex "/sign (in|up)/i"
playwright-cli eval "document.title"
playwright-cli eval "el => el.textContent" e5
# get element id, class, or any attribute not visible in the snapshot
playwright-cli eval "el => el.id" e5
playwright-cli eval "el => el.getAttribute('data-testid')" e5
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
playwright-cli resize 1920 1080
playwright-cli close
```

### Navigation

```bash
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

### Keyboard

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
```

### Mouse

```bash
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mouseup right
playwright-cli mousewheel 0 100
```

### Save as

```bash
playwright-cli screenshot
playwright-cli screenshot e5
playwright-cli screenshot --filename=page.png
playwright-cli screenshot --hires
playwright-cli pdf --filename=page.pdf
```

### Tabs

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-close 2
playwright-cli tab-select 0
```

### Storage

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json

# Cookies
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id abc123
playwright-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear

# LocalStorage
playwright-cli localstorage-list
playwright-cli localstorage-get theme
playwright-cli localstorage-set theme dark
playwright-cli localstorage-delete theme
playwright-cli localstorage-clear

# SessionStorage
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

### Auth profiles

Additional storage profiles live in `~/.config/playwright-auth/<name>.json`.

Load another profile:
```bash
playwright-cli -s=work open about:blank
playwright-cli -s=work state-load ~/.config/playwright-auth/work.json  # before navigating
playwright-cli -s=work goto https://site.com
```

Capture a profile from your real, logged-in Chrome (JSON only, no profile copy):
attach and visit each required origin per "Connecting to your existing browser", then:
```bash
playwright-cli --s=chrome state-save ~/.config/playwright-auth/myprofile.json
playwright-cli --s=chrome detach
```
`state-save` includes all context cookies (unrelated sites too) and localStorage for
visited origins; it excludes sessionStorage, IndexedDB, and cache. Treat the JSON as
live credentials: keep it out of git and `chmod 600`.

### Network

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

### DevTools

```bash
playwright-cli console
playwright-cli console warning
playwright-cli requests
playwright-cli request 5
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli run-code --filename=script.js
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start video.webm
playwright-cli video-chapter "Chapter Title" --description="Details" --duration=2000
playwright-cli video-stop

# annotate each subsequent action with a callout naming the action and highlighting the target
playwright-cli video-show-actions --duration=600 --position=top-right
playwright-cli video-hide-actions

# launch the dashboard for UI review / design feedback — user annotates the page, you receive the annotated screenshot, snapshot, and notes
playwright-cli show --annotate

# generate a Playwright locator for an element from its ref or selector
playwright-cli generate-locator e5 --raw

# show a persistent highlight overlay for an element, optionally with a custom style
playwright-cli highlight e5
playwright-cli highlight e5 --style="outline: 3px dashed red"
# hide a single element highlight, or all page highlights when no target is given
playwright-cli highlight e5 --hide
playwright-cli highlight --hide
```

## Raw output

The global `--raw` option strips page status, generated code, and snapshot sections from the output, returning only the result value. Use it to pipe command output into other tools. Commands that don't produce output return nothing.

```bash
playwright-cli --raw eval "JSON.stringify(performance.timing)" | jq '.loadEventEnd - .navigationStart'
playwright-cli --raw eval "JSON.stringify([...document.querySelectorAll('a')].map(a => a.href))" > links.json
playwright-cli --raw snapshot > before.yml
playwright-cli click e5
playwright-cli --raw snapshot > after.yml
diff before.yml after.yml
TOKEN=$(playwright-cli --raw cookie-get session_id)
playwright-cli --raw localstorage-get theme
```

For structured output wrapping every reply as JSON, pass --json
```bash
playwright-cli list --json
```

## Open parameters
```bash
# Use specific browser when creating session
playwright-cli open --browser=chrome
playwright-cli open --browser=firefox
playwright-cli open --browser=webkit
playwright-cli open --browser=msedge

# Emulate a generic mobile device (Pixel 10 for Chromium, iPhone 17 for WebKit).
# Prefer this when a mobile layout is acceptable: mobile pages are usually
# lighter, so snapshots are smaller and cheaper.
playwright-cli open --mobile
playwright-cli open --device="iPhone 15"

# Use persistent profile (by default profile is in-memory)
playwright-cli open --persistent
# Use persistent profile with custom directory
playwright-cli open --profile=/path/to/profile

# Connect to browser via Playwright Extension
playwright-cli attach --extension=chrome

# Connect to a running Chrome or Edge by channel name
playwright-cli attach --cdp=chrome
playwright-cli attach --cdp=msedge

# Connect to a running browser via CDP endpoint
playwright-cli attach --cdp=http://localhost:9222

# Start with config file
playwright-cli open --config=my-config.json

# Close the browser
playwright-cli close
# Detach from an attached browser (leaves the external browser running)
playwright-cli -s=msedge detach
# Delete user data for the default session
playwright-cli delete-data
```

## Connecting to your existing browser

To drive a browser you already have open (logged-in sessions, your real profile), attach to
it. The Playwright extension is the reliable path: plain `--cdp=chrome` needs the browser
started with remote debugging, and a normally-launched Chrome has no `DevToolsActivePort`,
so that attach fails.

> **MANDATORY after extension attach:** never issue the first HTTP(S) `goto` as a standalone
> command. Chain it with the `emulateMedia` command below using `&&`, and append the requested
> capture (`screenshot`/`pdf`) to the same chain, so capture cannot run if theme setup fails.
> `emulateMedia` removes Playwright's forced-light override so the page follows the attached
> browser's color scheme, affecting CSS, `matchMedia`, computed styles, screenshots, and PDFs.
> It runs once per session (guarded) unless the task explicitly requires a forced scheme.

```bash
# attach to your running Chrome via the Playwright extension
playwright-cli attach --extension=chrome
# -> creates a session named `chrome`; drive it with --s=chrome
# First goto + theme (+ capture) as ONE chain. Navigate before run-code (it hangs on the
# initial chrome-extension:// relay page); theme is set at the earliest safe point, not at
# capture time, so earlier matchMedia/computed-style work is already correct.
playwright-cli --s=chrome goto https://example.com \
  && playwright-cli --s=chrome run-code "async page => { await page.emulateMedia({ colorScheme: null }); const c = page.context(); if (!c.__pwTheme) { c.__pwTheme = true; c.on('page', p => p.emulateMedia({ colorScheme: null }).catch(() => {})); } }" \
  && playwright-cli --s=chrome screenshot --filename=page.png
# later commands in the session need no repeat of the theme step (listener covers new tabs)
playwright-cli --s=chrome snapshot
# disconnect automation but leave your browser running
playwright-cli --s=chrome detach
```

- The extension scopes automation to the tab it connected through; `tab-list` shows that
  relay tab. Use `goto` or `tab-new` to reach the page you want.

### Following the browser color scheme

Playwright otherwise emulates `prefers-color-scheme: light` on every controlled page, so an
attached dark-mode Chrome renders light. `colorScheme: null` removes that override so the page
uses the real browser/OS theme; the `context.on('page', ...)` listener applies it to future
tabs. To force a scheme instead, pass `'dark'` or `'light'`. Playwright config cannot express
this (`no-override`) for an extension-attached context, so it must be set at runtime, and
`run-code` hangs on the `chrome-extension://` relay page, so the active page must be HTTP(S)
first. Verify with:
`playwright-cli --s=chrome --raw eval "window.matchMedia('(prefers-color-scheme: dark)').matches"`

### File uploads in extension-attached Chrome

Chrome extension sessions can reject the normal file chooser flow with
`DOM.setFileInputFiles: Not allowed`. This is a Chrome protocol restriction, not a workspace
path restriction. When the page has a drop zone, prefer `drop --path` before clicking its
upload button:

```bash
# Use the outer drop-zone ref from the snapshot, not its text child.
playwright-cli --s=chrome drop e53 --path=/absolute/path/document.pdf
playwright-cli --s=chrome snapshot e51  # verify the filename is attached
```

If a failed `upload` leaves Playwright stuck in file-chooser modal state, detach and reattach
before retrying. Verify that the page displays the expected filename after `drop` completes.

## URLs with `&` on Windows

On Windows, `cmd.exe` and PowerShell treat `&` as a command separator, so URLs with multiple query parameters get truncated before `playwright-cli` runs. Escape `&` with `^&` in `cmd.exe`, or use `--%` in PowerShell:

```batch
playwright-cli goto "https://example.com/?a=1^&b=2"
```

```powershell
playwright-cli --% goto "https://example.com/?a=1&b=2"
```

## Snapshots

After each command, playwright-cli provides a snapshot of the current browser state.

```bash
> playwright-cli goto https://example.com
### Page
- Page URL: https://example.com/
- Page Title: Example Domain
### Snapshot
[Snapshot](.playwright-cli/page-2026-02-14T19-22-42-679Z.yml)
```

You can also take a snapshot on demand using `playwright-cli snapshot` command. All the options below can be combined as needed.

```bash
# default - save to a file with timestamp-based name
playwright-cli snapshot

# save to file, use when snapshot is a part of the workflow result
playwright-cli snapshot --filename=after-click.yaml

# snapshot an element instead of the whole page
playwright-cli snapshot "#main"

# limit snapshot depth for efficiency, take a partial snapshot afterwards
playwright-cli snapshot --depth=4
playwright-cli snapshot e34

# include each element's bounding box as [box=x,y,width,height]
playwright-cli snapshot --boxes
```

### Where snapshots are saved

Snapshots, traces, and downloads go to the directory in `PLAYWRIGHT_MCP_OUTPUT_DIR`, which
is exported in `~/.zshenv` to `/tmp/.playwright-cli`, so every session lands there by
default. Small snapshots are printed inline and never hit disk. The env var is read when the
browser is launched or attached.

Without that var, it falls back to `.playwright-cli/` in the current working directory (or
`<tmpdir>/.playwright-cli` when the cwd is a system or read-only dir). To override the
location for a single session, set it inline:

```bash
PLAYWRIGHT_MCP_OUTPUT_DIR=/path/to/dir playwright-cli attach --extension=chrome
```

### Searching large snapshots

Use `find` to return matching nodes with three lines of surrounding context instead of capturing the full snapshot:

```bash
playwright-cli find "Add to cart"
playwright-cli find --regex "\\$[0-9]+\\.[0-9]{2}"
```

## Targeting elements

By default, use refs from the snapshot to interact with page elements.

```bash
# get snapshot with refs
playwright-cli snapshot

# interact using a ref
playwright-cli click e15
```

You can also use css selectors or Playwright locators.

```bash
# css selector
playwright-cli click "#main > button.submit"

# role locator
playwright-cli click "getByRole('button', { name: 'Submit' })"

# test id
playwright-cli click "getByTestId('submit-button')"
```

## Browser Sessions

```bash
# create new browser session named "mysession" with persistent profile
playwright-cli -s=mysession open example.com --persistent
# same with manually specified profile directory (use when requested explicitly)
playwright-cli -s=mysession open example.com --profile=/path/to/profile
playwright-cli -s=mysession click e6
playwright-cli -s=mysession close  # stop a named browser
playwright-cli -s=mysession delete-data  # delete user data for persistent session

playwright-cli list
# Close all browsers
playwright-cli close-all
# Forcefully kill all browser processes
playwright-cli kill-all
```

## Installation

If global `playwright-cli` command is not available, try a local version via `npx playwright cli`:

```bash
npx --no-install playwright --version
```

When local version is available, use `npx playwright cli` in all commands. Otherwise, install `playwright-cli` as a global command:

```bash
npm install -g @playwright/cli@latest
```

## Example: Form submission

```bash
playwright-cli open https://example.com/form
playwright-cli snapshot

playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli snapshot
playwright-cli close
```

## Example: Multi-tab workflow

```bash
playwright-cli open https://example.com
playwright-cli tab-new https://example.com/other
playwright-cli tab-list
playwright-cli tab-select 0
playwright-cli snapshot
playwright-cli close
```

## Example: Debugging with DevTools

```bash
playwright-cli open https://example.com
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console
playwright-cli requests
playwright-cli close
```

```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli tracing-stop
playwright-cli close
```

## Example: Interactive session

Ask the user for UI review or design feedback. The user draws boxes on the live page and types comments; you receive the annotated screenshot, the snapshot of the marked region, and the user's notes. Use this whenever the user asks for "UI review", "design feedback", or to "ask the user what they think / want / mean":

```bash
playwright-cli open https://example.com
playwright-cli show --annotate
```

## Specific tasks

* **Running and Debugging Playwright tests** [references/playwright-tests.md](references/playwright-tests.md)
* **Request mocking** [references/request-mocking.md](references/request-mocking.md)
* **Running Playwright code** [references/running-code.md](references/running-code.md)
* **Browser session management** [references/session-management.md](references/session-management.md)
* **Spec-driven testing (plan / generate / heal)** [references/spec-driven-testing.md](references/spec-driven-testing.md)
* **Storage state (cookies, localStorage)** [references/storage-state.md](references/storage-state.md)
* **Test generation** [references/test-generation.md](references/test-generation.md)
* **Tracing** [references/tracing.md](references/tracing.md)
* **Video recording** [references/video-recording.md](references/video-recording.md)
* **Inspecting element attributes** [references/element-attributes.md](references/element-attributes.md)
