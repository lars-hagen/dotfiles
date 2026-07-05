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

Always use `https://www.facebook.com/messages/`; `messenger.com` has a separate session and shows
a login wall. See troubleshooting.md for the symptom.

## Fallback: storage-state (headless, no attach) — non-e2ee threads only

Only when you cannot attach to a live browser (e.g. CI, headless box). This reuses exported
cookies. It is strictly less safe: the file is a live session key.

> **e2ee limitation.** storage-state carries cookies (and optionally localStorage; the filter
> below drops it with `origins: []`) but **never** IndexedDB/OPFS, where Messenger keeps the
> end-to-end-encryption device keys. A context loaded from cookies
> alone is a *new device*: `/messages/e2ee/t/` threads will not decrypt and you will hit a
> "restore secure storage" / PIN prompt. Use this fallback for non-e2ee threads only. To read
> e2ee history headless, use the persistent-profile method below instead.

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

## Headless with your login (persistent profile, e2ee-capable)

When you want your own login in a headless Playwright browser *and* need e2ee threads to
decrypt, use a persistent profile. Unlike storage-state it keeps IndexedDB/OPFS, so the e2ee
device keys persist between runs. `open` is headless by default (`--headed` shows the window).

One-time bootstrap (must be headed: login, new-device approval, and e2ee secure-storage restore
all need interaction):

```bash
# pick a profile dir OUTSIDE any git-tracked path; treat it like a credential store
PROFILE="$HOME/.local/share/fb/profile"
mkdir -p "$PROFILE" && chmod 700 "$PROFILE"
# headed, persistent: log in, approve this device, and restore secure storage with your
# Messenger PIN so e2ee threads decrypt on this profile
bunx @playwright/cli -s=fb open --headed --persistent --profile="$PROFILE" \
  "https://www.facebook.com/messages/t/"
# open an e2ee thread once and complete any "restore secure storage" / PIN prompt, then:
bunx @playwright/cli -s=fb close
```

Subsequent runs reuse that profile headless; cookies and e2ee keys are already in it:

```bash
bunx @playwright/cli -s=fb open --persistent --profile="$PROFILE" \
  "https://www.facebook.com/messages/t/"
# read/send exactly as with attach; the history loader in reading.md works here too
bunx @playwright/cli -s=fb close
```

The reading/sending/manage recipes are written `-s=chrome`; under this profile swap every
`-s=chrome` for `-s=fb` (or whatever session name you opened with).

Caveats:

- **Detection.** Headless plus a persistent profile is more fingerprintable; Facebook may throw
  a checkpoint/captcha. Resolve it once in `--headed` on the same profile, then go headless
  again. Keep actions human-paced (see troubleshooting "Rate limiting").
- **Single writer.** Do not run this profile headless while the same account's Chrome is also
  live on e2ee; concurrent device sessions can desync secure storage. Close one before the other.
- **Security.** The profile dir holds session cookies *and* e2ee key material: `chmod 700`, keep
  it out of the repo, never commit it. Deleting the dir forces a fresh login + PIN restore.
- If you only need non-e2ee threads, the lighter storage-state fallback above is enough.

## Multiple accounts / windows

Use distinct session names so they do not collide:

```bash
bunx @playwright/cli -s=fb-main attach --extension=chrome
bunx @playwright/cli -s=fb-main goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli list           # see all live sessions
```
