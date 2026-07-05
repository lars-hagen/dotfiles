---
name: facebook-messenger
description: "Manage your own Facebook Messenger from the command line via playwright-cli attached to your logged-in Chrome: list conversations, read threads, send and reply to messages, search people, mark read/unread, archive, mute. Uses the live browser session (no stored credentials). Load when the task is reading or sending Facebook/Messenger messages."
allowed-tools: Bash(playwright-cli:*) Bash(bunx:*) Bash(npx:*) Bash(bun:*) Bash(jq:*)
---

# Manage Facebook Messenger with playwright-cli

Drive your own Facebook Messenger through `playwright-cli` attached to your already-logged-in
Chrome via the browser extension. No passwords, no stored cookies: the skill rides your live
session. Builds on the `playwright-cli` skill (read it for the full command surface).

## Non-negotiable rules

1. **Run under Node, never the Bun runtime.** The extension bridge needs a WebSocket 101
   upgrade that Bun's HTTP client drops, so `bunx --bun` hangs forever. Use one of:
   - `bunx @playwright/cli <cmd>`   (no `--bun`; runs via the package's node shebang)
   - `npx @playwright/cli <cmd>`
   - a global `playwright-cli <cmd>` (the binary `npm i -g @playwright/cli` installs)
   Every example below assumes one of these. Pick one prefix and keep it consistent.
2. **Use `facebook.com`, not `messenger.com`.** They have separate sessions; your login lives
   on `facebook.com`. All thread URLs are under `https://www.facebook.com/messages/`.
3. **Snapshot, then act on refs.** Facebook's CSS classes are obfuscated and rotate. Never
   target classes. Use `snapshot` to get `eNN` refs, or role/aria locators (below).
4. **Never write message contents or cookie values into committed files or noisy logs.**
   This skill dir is git-tracked. Treat thread text as private; use `--raw` and scope output.
5. **Draft in the user's own voice for that specific thread.** Before composing or replying,
   read back the user's recent messages in THAT conversation (from the live thread or the
   local archive) and mirror how they actually write to that person: length, greeting and
   sign-off (or none), formality, language and code-switching (e.g. Danish vs English, æ/ø/å),
   emoji and punctuation habits, capitalization, slang and pet names. Style is per-thread, not
   global: the user writes differently to a partner, a parent, and a group. When the samples
   are thin or mixed, keep it short and neutral and ask before sending. Always show the draft
   for approval first; never send a message that sounds like the assistant instead of the user.
6. **A draft must fit the LATEST state of the thread, including who spoke last and when.**
   Before drafting, read the tail of the conversation and check timestamps (use the stored
   `ts` / `meta.lastSender` + `meta.newestTs`, not the relative `at` label):
   - If the OTHER person sent the last message, you are replying; answer what is actually open.
   - If the USER sent the last message, a new message is a FOLLOW-UP / double-text after
     silence, not a reply: do not re-answer questions already answered, and acknowledge the
     gap if it is long.
   - Respect the timeline. FB shows recent messages with a time only and no date, so a line
     can look current but be days, weeks, or months old. Never resurface a stale topic (an
     old offer, an old question) as if it were live. Anchor recency to real dates and let the
     gap shape the message (e.g. a long silence, or that they were clearly out late).
7. **Reason from the RECENT window, not the whole archive.** The cache stores full history for
   the record, but context for a draft, a summary, or "what's going on with X" comes from the
   tail only. Default to the last ~14 days (and at most the last ~15 messages) by `ts`; widen
   only if the user asks or the recent window is too thin to read the situation. Anything older
   is cold archive: do not raise it, quote it, or fold it into a draft unless the user brings it
   up or the other person just reintroduced it. It is the current year; a line from a year or
   two ago is history, not live context, and surfacing it unprompted is wrong even when the
   archive technically contains it. Style sampling (rule 5) may look further back, since voice
   is stable, but topical context must stay recent.

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
| In-thread message   | aria-label starts with `At ` (`At <date>, <Sender>: <text>`); `[role=row]` is empty in-thread, it only matches the inbox rail |

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
* **Reading: list conversations, open threads, scroll history, pull attached images, build a local archive/cache, unread** [references/reading.md](references/reading.md)
* **Sending: compose, reply, links, attachments, reactions** [references/sending.md](references/sending.md)
* **Search and manage: find people, mark read/unread, archive, mute, delete** [references/manage.md](references/manage.md)
* **Troubleshooting: bun/WS hang, stale refs, login walls, e2ee, rate limits** [references/troubleshooting.md](references/troubleshooting.md)
