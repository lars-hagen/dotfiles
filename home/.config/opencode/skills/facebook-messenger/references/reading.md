# Reading conversations and messages

All commands assume an attached session (`-s=chrome`) and Node runtime (no `--bun`).

## List recent conversations

Open the inbox and snapshot the left rail. Each conversation is a `role=row` whose link name
is the contact/group name; unread rows are usually bold and may carry an "Unread" indicator.

```bash
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/"
bunx @playwright/cli -s=chrome snapshot --depth=12
```

Extract just the conversation names and unread state without dumping the whole tree:

```bash
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[role=grid] [role=row]')].map(r => {
    const link = r.querySelector('a[role=link]');
    return {
      name: link?.getAttribute('aria-label') || link?.textContent?.trim(),
      href: link?.getAttribute('href'),
      unread: /unread|Unread/.test(r.getAttribute('aria-label') || '') ||
              !!r.querySelector('[aria-label*=\"Unread\" i]')
    };
  }).filter(x => x.name)
)"
```

`href` gives the stable thread path (`/messages/t/<id>/` or `/messages/e2ee/t/<id>/`). Navigate
straight to a known thread with `goto "https://www.facebook.com<href>"`.

## Open a specific conversation

```bash
# by visible name in the rail
bunx @playwright/cli -s=chrome click "getByRole('link', { name: 'Jane Doe' })"
# or by direct thread URL
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/100000000000000/"
```

## Read the visible messages in the open thread

The message list region is labelled `Messages in conversation with <Name>`. Snapshot only that
region to avoid the surrounding chrome:

```bash
bunx @playwright/cli -s=chrome snapshot "getByLabel('Messages in conversation with Jane Doe')"
```

Pull message rows as structured text (sender hints come from aria-labels / row grouping):

```bash
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[aria-label^=\"Messages in conversation\"] [role=row]')]
    .map(r => r.innerText.trim()).filter(Boolean).slice(-30)
)"
```

`slice(-30)` keeps the last 30 message rows. Adjust as needed.

## Load older history (scroll up)

Messenger lazy-loads history on upward scroll. Scroll the message pane and re-read:

```bash
# focus the message area, then scroll up via wheel (negative dy)
bunx @playwright/cli -s=chrome hover "getByLabel('Messages in conversation with Jane Doe')"
bunx @playwright/cli -s=chrome mousewheel 0 -1200
bunx @playwright/cli -s=chrome mousewheel 0 -1200
bunx @playwright/cli -s=chrome snapshot "getByLabel('Messages in conversation with Jane Doe')"
```

Repeat the wheel + snapshot loop until you reach the date range you need. There is no "jump to
oldest"; pace the scrolls (see troubleshooting for rate limits).

## Find unread threads only

```bash
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[role=grid] [role=row]')]
    .filter(r => !!r.querySelector('[aria-label*=\"Unread\" i]'))
    .map(r => r.querySelector('a[role=link]')?.getAttribute('aria-label'))
    .filter(Boolean)
)"
```
