# Sending and replying

All commands assume an attached session (`-s=chrome`) and Node runtime (no `--bun`).
The composer is a contenteditable `textbox` labelled `Write to <Name>`. **Enter sends**;
Shift+Enter inserts a newline.

## Send a message to an open thread

```bash
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to Jane Doe' })" "On my way" --submit
```

`--submit` types the text then presses Enter. To stage without sending, drop `--submit` and
inspect with a snapshot first.

If the composer label is unknown (name varies), target it generically and submit by key:

```bash
bunx @playwright/cli -s=chrome snapshot --depth=14          # find the composer ref, e.g. e42
bunx @playwright/cli -s=chrome fill e42 "Sounds good"
bunx @playwright/cli -s=chrome press Enter
```

## Multi-line message

Enter sends, so build newlines with Shift+Enter between fills:

```bash
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to Jane Doe' })" "Line one"
bunx @playwright/cli -s=chrome keydown Shift
bunx @playwright/cli -s=chrome press Enter
bunx @playwright/cli -s=chrome keyup Shift
bunx @playwright/cli -s=chrome type "Line two"
bunx @playwright/cli -s=chrome press Enter
```

## Start a new conversation

```bash
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli -s=chrome click "getByRole('link', { name: 'New message' })"
# in the "To" field, type the recipient then pick from the suggestion list
bunx @playwright/cli -s=chrome fill "getByRole('combobox', { name: 'To' })" "Jane Doe"
bunx @playwright/cli -s=chrome snapshot --depth=12          # locate the suggestion option ref
bunx @playwright/cli -s=chrome click "getByRole('option', { name: 'Jane Doe' })"
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to Jane Doe' })" "Hi Jane" --submit
```

## Send a link

Links send as plain text and Messenger auto-previews them:

```bash
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to Jane Doe' })" "https://example.com" --submit
```

## Attach a file

Use the attachment button, then the OS file chooser via `upload`:

```bash
bunx @playwright/cli -s=chrome snapshot --depth=14          # find "Attach a file"/"Add files" button ref
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Attach a file' })"
bunx @playwright/cli -s=chrome upload /absolute/path/to/image.png
bunx @playwright/cli -s=chrome press Enter
```

If `upload` is blocked, the CLI restricts file access to workspace roots by default; set
`PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1` or place the file under the working dir.

## React to a message

Hover the target message row to reveal its action toolbar, open the reaction picker, choose:

```bash
bunx @playwright/cli -s=chrome snapshot "getByLabel('Messages in conversation with Jane Doe')"
bunx @playwright/cli -s=chrome hover e57                    # the message row ref
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'React' })"
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Like' })"
```

## Message yourself (note-to-self)

Your self-thread is not in the rail. Open it by your own user id (read it once with
`require('CurrentUserInitialData').USER_ID`, or grab `__user=` from any request URL):

```bash
bunx @playwright/cli -s=chrome --raw eval "require('CurrentUserInitialData').USER_ID"   # -> 1000...
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/<own_id>/"
```

That legacy URL may open a pre-e2ee view gated by a **Continue** button ("sent before this chat
was secured... You can't reply"). Click it to land on the sendable e2ee self-thread (a different
`/messages/e2ee/t/<id>/`). The self-composer has **no name**, so its label is `Write to ` with a
trailing space; target it exactly:

```bash
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Continue' })"   # only if the gate shows
bunx @playwright/cli -s=chrome fill "getByRole('textbox', { name: 'Write to ', exact: true })" "note to self" --submit
```

## Verify a send

After sending, confirm the message landed rather than assuming. Match in-thread messages by their
`At <date>, <Sender>: <text>` aria-label, not `[role=row]` (see reading.md):

```bash
bunx @playwright/cli -s=chrome --raw eval "
  [...document.querySelectorAll('[aria-label^=\"Messages in conversation\"] [aria-label^=\"At \"]')]
    .slice(-1)[0]?.getAttribute('aria-label')"
```
