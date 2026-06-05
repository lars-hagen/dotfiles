# Auth, sessions, and security

## Primary method: live extension attach (no stored credentials)

This is the method this skill is built on. It controls the Chrome you are already logged into,
so there is nothing to authenticate and nothing to store.

```bash
# 1. Chrome must be running, logged into facebook.com, with the
#    "Playwright MCP Bridge" extension installed.
# 2. PLAYWRIGHT_MCP_EXTENSION_TOKEN must be set (it is, in ~/.zshenv).
bunx @playwright/cli attach --extension=chrome     # NOT --bun
```

Attach prints a session named `chrome`. Target it on every command:

```bash
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli -s=chrome detach              # release, leaves Chrome open
```

The token in the env must match the token configured in the extension. If attach connects but
is rejected, they differ: re-copy the token from the extension popup into `~/.zshenv`.

## Why not messenger.com

`messenger.com` keeps a session separate from `facebook.com`. Your login is on `facebook.com`,
so `messenger.com` shows a login wall (search box reads "Email or phone number"). Always use
`https://www.facebook.com/messages/`.

## Fallback: storage-state (headless, no attach)

Only when you cannot attach to a live browser (e.g. CI, headless box). This reuses exported
cookies. It is strictly less safe: the file is a live session key.

```bash
# capture once from an authenticated context (filter to facebook only!)
bunx @playwright/cli -s=chrome state-save /tmp/fb-state.full.json
jq '{cookies: [.cookies[] | select(.domain|test("facebook\\.com$"))], origins: []}' \
  /tmp/fb-state.full.json > "$HOME/.local/share/fb/messenger-state.json"
chmod 600 "$HOME/.local/share/fb/messenger-state.json"
rm -f /tmp/fb-state.full.json      # the full dump holds EVERY site's cookies; delete it
```

Then drive a headless context that loads only that state:

```bash
bunx @playwright/cli --config "$HOME/.local/share/fb/cli.config.json" \
  open "https://www.facebook.com/messages/t/"
# cli.config.json sets browser.contextOptions.storageState to the filtered file
```

### Security rules for the fallback

- **Never** put the state file inside this repo or any git-tracked path. Use
  `~/.local/share/fb/` (outside the dotfiles tree) with `chmod 600`.
- A blanket `state-save` exports the **entire** browser profile (thousands of cookies across
  banking, email, password managers). Always filter to `facebook.com` and delete the full dump.
- Facebook session cookies (`c_user`, `xs`, `datr`, `fr`) are session-hijack tokens. Rotate by
  logging out/in on Facebook if a file leaks.
- Prefer the live attach method; it needs none of this.

## Multiple accounts / windows

Use distinct session names so they do not collide:

```bash
bunx @playwright/cli -s=fb-main attach --extension=chrome
bunx @playwright/cli -s=fb-main goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli list           # see all live sessions
```
