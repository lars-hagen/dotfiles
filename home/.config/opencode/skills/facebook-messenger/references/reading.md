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

Pull messages as structured text. Each message carries an `At <date>, <Sender>: <text>`
aria-label, which gives timestamp + sender + body in one string (the generic `[role=row]`
selector returns nothing inside a thread; it only matches inbox-rail rows):

```bash
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[aria-label^=\"Messages in conversation\"] [aria-label^=\"At \"]')]
    .map(e => e.getAttribute('aria-label')).slice(-30)
)"
```

`slice(-30)` keeps the last 30 messages. Adjust as needed.

## Load older history (one command, no manual scrolling)

Messenger lazy-loads history only on a **real** upward wheel; the server backfills each chunk
over the live channel. Synthetic events (`element.scrollTop = 0`, `dispatchEvent(new
WheelEvent(...))`) are `isTrusted: false` and the virtualized list ignores them, so you must
drive the CDP mouse wheel. The list is also **virtualized**: only ~20 rows stay in the DOM at
once, so a single `evaluateAll` at the end returns just the final viewport and loses
everything that scrolled out. The loop below therefore reads each step and prepends the newly
revealed older messages (anchoring on the current oldest label) to build one chronological,
gap-free list. It auto-stops when no new older messages appear for several steps (top
reached), the `wantMessages` cap is met, or `iters` runs out:

```bash
bunx @playwright/cli -s=chrome --raw run-code "async (page) => {
  const pane = '[aria-label^=\"Messages in conversation\"]';
  const box = await page.locator(pane).boundingBox();
  if (!box) throw new Error('thread pane not rendered; open a thread first');
  await page.mouse.move(box.x + box.width/2, box.y + box.height/2);
  const msgs = page.locator(pane + ' [aria-label^=\"At \"]');   // scope to this thread
  const read = () => msgs.evaluateAll(els => els.map(e => e.getAttribute('aria-label')));
  let acc = await read();
  let stable = 0, iters = 0;
  while (stable < 6 && iters < 120 && acc.length < 100) {  // raise 100 for more history
    await page.mouse.wheel(0, -1800);
    await page.waitForTimeout(900);           // pace: server backfill + rate limits
    const win = await read();
    const idx = win.length ? win.indexOf(acc[0]) : -1;       // overlap anchor (oldest seen)
    const before = idx >= 0 ? win.slice(0, idx)
                 : (win.length ? win.filter(l => !acc.includes(l)) : []);
    if (before.length) { acc = before.concat(acc); stable = 0; } else stable++;
    iters++;
  }
  return acc;
}"
```

Each `At <date>, <Sender>: <text>` aria-label is one message in order (photo/sticker messages
omit the `: <text>` and read as `At <date>, <Sender>`). Tune `stable`/`iters`/`100`/the
`900`ms wait per thread length and connection (see troubleshooting for rate limits). For a
short read of just what is on screen, use the snapshot/eval recipes above instead.

> Why not curl / replay the network request? For end-to-end-encrypted threads
> (`/messages/e2ee/t/`) you cannot. History arrives over an MQTT WebSocket
> (`wss://gateway.facebook.com`, `wss://edge-chat.facebook.com`) as ciphertext and is decrypted
> in-page by a WASM module using device keys in browser-local secure storage; the GraphQL calls
> that do fire (`EBMessageMetadataQueryQuery`, etc.) carry only metadata, never message bodies.
> Reading the already-decrypted DOM, as above, is the only reliable path. (Non-e2ee threads do
> expose a plaintext GraphQL message-list query, but driving the live page is less brittle than
> harvesting its rotating `fb_dtsg`/`lsd`/`doc_id` tokens for raw curl.)

## Pull attached images (often relevant context)

Attached photos are decrypted in-page too: they render as inline `data:` URIs (e2ee) or
`blob:`/`https` elements, never plain CDN bytes you could curl. The
`scripts/pull-thread-images.ts` helper saves the originals from the **currently open** thread
and prints a manifest; `read` the saved files so the images factor into your read. Open the
thread (and run the history loader first if you need older photos) before invoking it:

```bash
bun <SKILL_DIR>/scripts/pull-thread-images.ts --session fb --out /tmp/fbimg
# -> {"out":"/tmp/fbimg","count":1,"images":[{"file":".../img-1.jpg","w":1920,"h":1080,"at":"At 10:56 PM, Frederik"}], ...}
```

It filters out avatars and emoji, parses `data:` URIs inline (fetching a `data:` URL is
CSP-blocked) and `fetch()`es `blob:`/`https` ones, dedupes, and skips images narrower than
`--min` px (default 64). Use `--limit N` to keep only the N most recent. It only reads what is
loaded in the DOM, so it pairs with the history loader and stays cheap. (Because the list is
virtualized, run it after a short scroll if you need a photo that scrolled out of view; the
cache script below accumulates images across the whole scroll for you.)

## Build a local archive (cache) of recent threads

To snapshot the last N conversations (last N messages each, with image attachments) to disk
for offline reading, use `scripts/sync-cache.ts`. It sweeps the inbox rail, then per thread
scrolls while accumulating messages and images (handling virtualization), and writes an
idempotent, resumable cache. New threads get a deep backfill; already-cached threads get a
cheap shallow pass that splices in only newer messages. The merge keeps stored history up to
the longest contiguous suffix whose messages also appear in the fresh window (set membership,
so a single new/edited message does not break overlap detection), capped at the fresh window
length so older history is never truncated by a smaller `--messages` cap. Merge keys are the
first-word sender + text, because Facebook renders the same person as a full name on the
latest message but a first name once it groups (and timestamps are relative, so labels cannot
key it). Requires the persistent-profile session (e2ee keys live in the profile, not cookies);
see auth-and-setup.

Scrolling is adaptive: each step waits only until the scroll position settles (not a fixed
delay) and stops as soon as the scroll is pinned at the top/bottom, so short threads finish in
well under a second of confirmation instead of a multi-second fixed tax (~10s/thread shallow).

```bash
PROFILE="$HOME/.local/share/fb/profile"
bunx @playwright/cli -s=fb open --persistent --profile="$PROFILE" "https://www.facebook.com/messages/t/"
bun <SKILL_DIR>/scripts/sync-cache.ts --session fb --threads 100 --messages 100
```

Data is written **outside** this git-tracked skill (it is decrypted plaintext + photos), to a
`700` dir beside the profile: `${XDG_DATA_HOME:-$HOME/.local/share}/fb/cache/`:

```
cache/index.json                       [{id,name,kind,url,lastSynced,msgCount,imgCount}]
cache/index.md                         human-readable table, sorted by name
cache/by-name/<Name>                    symlink -> ../threads/<id> (browse by person)
cache/threads/<id>/meta.json           {id,name,kind,url,lastSynced,oldestAt,newestAt,...}
cache/threads/<id>/messages.json       [{label,at,sender,text,images:["images/<sha>.jpg"]}]
cache/threads/<id>/images/<sha256>.jpg deduped by content hash
```

You never need the numeric IDs: read `cache/index.md`, or open `cache/by-name/<Name>/messages.json`.
`sync-cache.ts` regenerates both views at the end of every run; regenerate them on demand (and
tidy any leftover raw pane names) with `bun <SKILL_DIR>/scripts/organize-cache.ts`.

Flags: `--session` (default `fb`), `--threads N`, `--messages N`, `--images false` (skip
attachments), `--min PX`, `--root DIR`, `--delay MS` (pause between threads, +-50% jitter),
`--force` (deep re-pull every thread), `--new-only` (skip threads already cached, no
navigation, for fast breadth widening or resuming an interrupted sweep; pair with a high
`--threads` to reach uncached conversations deeper in the rail). Re-run anytime; it is
incremental and resumable. The first deep backfill of each thread is the slow part; later
syncs are mostly shallow and fast, and `--new-only` skips done threads outright.

## Find unread threads only

```bash
bunx @playwright/cli -s=chrome --raw eval "JSON.stringify(
  [...document.querySelectorAll('[role=grid] [role=row]')]
    .filter(r => !!r.querySelector('[aria-label*=\"Unread\" i]'))
    .map(r => r.querySelector('a[role=link]')?.getAttribute('aria-label'))
    .filter(Boolean)
)"
```
