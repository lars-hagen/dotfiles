# Search and manage conversations

All commands assume an attached session (`-s=chrome`) and Node runtime (no `--bun`).

## Search for a person or thread

```bash
bunx @playwright/cli -s=chrome fill "getByRole('combobox', { name: 'Search Messenger' })" "Jane"
bunx @playwright/cli -s=chrome snapshot --depth=12          # locate the result row/link ref
bunx @playwright/cli -s=chrome click "getByRole('link', { name: 'Jane Doe' })"
```

Clear the search before browsing the full inbox again:

```bash
bunx @playwright/cli -s=chrome fill "getByRole('combobox', { name: 'Search Messenger' })" ""
```

## Per-conversation actions menu

Most management actions live behind the conversation's "Menu"/"More" button, exposed on hover
of a rail row or in the thread header. The reliable pattern: hover the row, open its menu,
then click the action by its accessible name.

```bash
# from the inbox rail
bunx @playwright/cli -s=chrome snapshot --depth=12          # find the target row ref, e.g. e30
bunx @playwright/cli -s=chrome hover e30
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Menu' })"
bunx @playwright/cli -s=chrome snapshot --depth=10          # read the menu items
```

Common menu item names (click by role=menuitem):

| Action          | Menu item name                          |
| --------------- | --------------------------------------- |
| Mark as read    | `Mark as read`                          |
| Mark as unread  | `Mark as unread`                        |
| Archive         | `Archive chat`                          |
| Mute / snooze   | `Mute notifications`                    |
| Delete          | `Delete chat`                           |
| Block           | `Block`                                 |

```bash
bunx @playwright/cli -s=chrome click "getByRole('menuitem', { name: 'Mark as read' })"
```

## Mark as read / unread

```bash
bunx @playwright/cli -s=chrome hover e30
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Menu' })"
bunx @playwright/cli -s=chrome click "getByRole('menuitem', { name: 'Mark as unread' })"
```

Opening a conversation also marks it read implicitly; use the menu when you must change state
without opening.

## Archive a conversation

```bash
bunx @playwright/cli -s=chrome hover e30
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Menu' })"
bunx @playwright/cli -s=chrome click "getByRole('menuitem', { name: 'Archive chat' })"
```

Archived chats live under the inbox filter menu ("Archived chats").

## Mute notifications

```bash
bunx @playwright/cli -s=chrome click "getByRole('menuitem', { name: 'Mute notifications' })"
bunx @playwright/cli -s=chrome snapshot --depth=8          # pick a duration radio, e.g. "15 minutes"
bunx @playwright/cli -s=chrome click "getByRole('radio', { name: 'Until I change it' })"
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Mute' })"
```

## Delete a conversation (destructive)

Deleting removes the thread from your inbox and **cannot be undone**. Confirm with the user
before running, and confirm the dialog explicitly.

```bash
bunx @playwright/cli -s=chrome click "getByRole('menuitem', { name: 'Delete chat' })"
bunx @playwright/cli -s=chrome snapshot --depth=8
bunx @playwright/cli -s=chrome click "getByRole('button', { name: 'Delete' })"
```

## Bulk triage pattern

To process several unread threads, resolve the unread list first (see reading.md), then loop
over thread URLs rather than rail refs (refs go stale as the list re-renders):

```bash
# 1) collect unread hrefs
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[role=grid] [role=row]')]
    .filter(r => r.querySelector('[aria-label*=\"Unread\" i]'))
    .map(r => r.querySelector('a[role=link]')?.getAttribute('href')).filter(Boolean)
)"
# 2) for each href: goto, read, optionally reply, then move on
bunx @playwright/cli -s=chrome goto "https://www.facebook.com/messages/t/<id>/"
```
