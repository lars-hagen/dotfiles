# Troubleshooting

## attach hangs / times out with no output

Cause: the command ran under the **Bun runtime**. Bun's HTTP client does not emit the `upgrade`
event on a 101 response, so the WebSocket handshake the extension bridge needs never completes.

Fix: never pass `--bun`. Run under Node:

```bash
bunx @playwright/cli attach --extension=chrome     # bunx WITHOUT --bun -> node shebang
# or
npx @playwright/cli attach --extension=chrome
```

Reference (the underlying bug and workarounds): gist "Playwright + Bun compatibility fixes".
Same rule applies to any WebSocket/CDP path (`--cdp`, `--endpoint`, `connectOverCDP`).

Other attach failures:
- Chrome not running, or the "Playwright MCP Bridge" extension not installed/enabled.
- `PLAYWRIGHT_MCP_EXTENSION_TOKEN` unset or mismatched with the extension's token. Re-copy the
  token from the extension popup into `~/.zshenv` and start a new shell.

## "Email or phone number" / login wall

You navigated to `messenger.com`, which has a separate session. Use
`https://www.facebook.com/messages/` instead. If `facebook.com` itself shows a login wall, the
attached Chrome is not logged in; log in manually in that Chrome, then retry.

## Stale element refs (`eNN` not found / wrong element)

Facebook re-renders aggressively; refs from an old snapshot expire. Re-`snapshot` immediately
before acting, or prefer durable targets:
- role/aria locators (`getByRole(...)`, `getByLabel(...)`)
- thread URLs (`/messages/t/<id>/`) over rail-row refs for navigation
In bulk loops, collect `href`s first, then `goto` each, instead of holding rail refs.

## Composer label unknown or changing

The composer aria-label is `Write to <Name>` and varies per thread. When the name is unknown,
snapshot the thread and use the contenteditable textbox ref, or:

```bash
bunx @playwright/cli -s=chrome eval "el => el.getAttribute('aria-label')" \
  "[contenteditable=true][role=textbox]"
```

## End-to-end-encrypted (e2ee) threads

URL is `/messages/e2ee/t/<id>/`. The composer and message DOM are the same role/aria pattern,
but some history may not be present if this device has not synced the e2ee thread. Reading works
for synced content; if the thread shows a "restore/secure storage" prompt, handle it manually in
Chrome first. e2ee bodies cannot be fetched via curl/HTTP replay (they arrive encrypted over
MQTT and are decrypted in-page); read the decrypted DOM, see reading.md "Load older history".

## Send did not go through

Enter sends, but a focus loss or a modal (e.g. message request, blocked recipient) can swallow
it. After `--submit`, verify by reading the last message row (see sending.md "Verify a send").
For first-time contacts you may land in **Message requests**; the message sends but sits in the
recipient's requests folder.

## Rate limiting / automation detection

Facebook flags rapid, scripted interaction. Keep it human-paced:
- insert short pauses between actions (a `goto` already waits for load)
- avoid tight loops of sends; batch reads, act deliberately
- if you hit a checkpoint/captcha, stop and resolve it manually in Chrome; do not script around it
Automating your own account is your call, but aggressive automation risks temporary blocks.

## Nothing renders / blank snapshot

The page may still be loading or virtualized. `reload`, wait, and re-snapshot. For long inboxes,
the rail is virtualized: only rendered rows appear in snapshots; scroll to load more.
