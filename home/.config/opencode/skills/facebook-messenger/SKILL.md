---
name: facebook-messenger
description: "Manage your own Facebook Messenger from the command line via playwright-cli attached to your logged-in Chrome: list conversations, read threads, send and reply to messages, search people, mark read/unread, archive, mute. Uses the live browser session (no stored credentials). Load when the task is reading or sending Facebook/Messenger messages."
allowed-tools: Bash(playwright-cli:*) Bash(bunx:*) Bash(npx:*) Bash(jq:*)
---

# Manage Facebook Messenger with playwright-cli

Drive your own Facebook Messenger through `playwright-cli` attached to your already-logged-in
Chrome via the browser extension. No passwords, no stored cookies: the skill rides your live
session. Builds on the `playwright-cli` skill (read it for the full command surface).

## Non-negotiable rules

1. **Run under Node, never the Bun runtime.** The extension bridge needs a WebSocket 101
   upgrade that Bun's HTTP client drops, so `bunx --bun` hangs forever. Use one of:
   - `bunx @playwright/cli <cmd>`   (no `--bun`; runs via the package's node shebang)
   - `npx playwright-cli <cmd>`
   - a global `playwright-cli <cmd>` (after `npm i -g @playwright/cli`)
   Every example below assumes one of these. Pick one prefix and keep it consistent.
2. **Use `facebook.com`, not `messenger.com`.** They have separate sessions; your login lives
   on `facebook.com`. All thread URLs are under `https://www.facebook.com/messages/`.
3. **Snapshot, then act on refs.** Facebook's CSS classes are obfuscated and rotate. Never
   target classes. Use `snapshot` to get `eNN` refs, or role/aria locators (below).
4. **Never write message contents or cookie values into committed files or noisy logs.**
   This skill dir is git-tracked. Treat thread text as private; use `--raw` and scope output.

## Setup (once per working session)

Requires `PLAYWRIGHT_MCP_EXTENSION_TOKEN` in the environment (already set in `~/.zshenv`) and
Chrome running with the Playwright MCP Bridge extension, logged into Facebook.

```bash
# attach to the running Chrome; creates a session named "chrome"
bunx @playwright/cli attach --extension=chrome
# every later command targets that session with -s=chrome
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
```

If attach hangs: you used `--bun` (see rule 1) or Chrome/extension is not running. See
[references/troubleshooting.md](references/troubleshooting.md).

When done, leave the browser open and release control:

```bash
bunx @playwright/cli -s=chrome detach
```

## Stable locators

| Target              | Locator                                                              |
| ------------------- | -------------------------------------------------------------------- |
| Conversation list   | `getByRole('row')` (left rail; each row's link name is the contact)  |
| Messenger search    | `getByRole('combobox', { name: 'Search Messenger' })`                |
| Open a conversation | `getByRole('link', { name: 'CONTACT NAME' })`                        |
| Message composer    | `getByRole('textbox', { name: 'Write to CONTACT NAME' })`            |
| Thread message area | aria-label `Messages in conversation with CONTACT NAME`              |

Thread URL forms: standard `…/messages/t/<id>/`, end-to-end-encrypted `…/messages/e2ee/t/<id>/`.

## Quick start: send a message

```bash
bunx @playwright/cli attach --extension=chrome
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
# open a thread by name
bunx @playwright/cli -s=chrome click "getByRole('link', { name: 'Jane Doe' })"
# type into the composer and send (Enter submits in Messenger)
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to Jane Doe' })" "On my way" --submit
bunx @playwright/cli -s=chrome detach
```

## Quick start: read latest from a thread

```bash
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli -s=chrome click "getByRole('link', { name: 'Jane Doe' })"
bunx @playwright/cli -s=chrome snapshot "getByLabel('Messages in conversation with Jane Doe')"
```

## Task references

* **Auth, sessions, storage-state fallback, security** [references/auth-and-setup.md](references/auth-and-setup.md)
* **Reading: list conversations, open threads, scroll history, unread** [references/reading.md](references/reading.md)
* **Sending: compose, reply, links, attachments, reactions** [references/sending.md](references/sending.md)
* **Search and manage: find people, mark read/unread, archive, mute, delete** [references/manage.md](references/manage.md)
* **Troubleshooting: bun/WS hang, stale refs, login walls, e2ee, rate limits** [references/troubleshooting.md](references/troubleshooting.md)
