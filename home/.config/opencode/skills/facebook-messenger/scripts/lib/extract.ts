/**
 * Shared helpers for the facebook-messenger scripts.
 *
 * Everything here drives `bunx @playwright/cli -s=<session> run-code` (no `--bun`;
 * runs the package node shebang). The run-code callbacks execute IN-PAGE, where the
 * environment is sandboxed (no fs/process/require) and a `fetch()` on a `data:` URL is
 * CSP-blocked, so attachment bytes are returned as base64 and written by the caller.
 */

/** Run a `async (page) => {...}` snippet in the page and parse its JSON result. */
export async function runCode(session: string, code: string): Promise<any> {
  const proc = Bun.spawn(
    ["bunx", "@playwright/cli", `-s=${session}`, "--raw", "run-code", code],
    { stdout: "pipe", stderr: "pipe" },
  );
  const raw = await new Response(proc.stdout).text();
  const err = await new Response(proc.stderr).text();
  const exit = await proc.exited;
  if (exit !== 0) {
    throw new Error(
      `run-code failed (session ${session}, exit ${exit}): ${(err || raw).slice(0, 400)}`,
    );
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error(
      `run-code returned no JSON (session ${session}): ${(raw || err).slice(0, 400)}`,
    );
  }
}

/** Run a plain playwright-cli subcommand (goto, click, ...) and return stdout. */
export async function cli(session: string, ...a: string[]): Promise<string> {
  const proc = Bun.spawn(["bunx", "@playwright/cli", `-s=${session}`, ...a], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const out = await new Response(proc.stdout).text();
  const err = await new Response(proc.stderr).text();
  const exit = await proc.exited;
  if (exit !== 0) {
    throw new Error(
      `playwright-cli ${a[0]} failed (session ${session}, exit ${exit}): ${(err || out).slice(0, 300)}`,
    );
  }
  return out;
}

/**
 * Extract attachment images from the open thread. e2ee photos render inline as `data:`
 * URIs (parsed directly) or `blob:`/`https` (fetched in-page with session creds).
 * Avatars (https profile pics) and emoji (32x32) are filtered out by alt/size.
 * Returns [{ mime, b64, w, h, at } | { error, src }].
 */
export const imageExtractor = (min: number) => `async (page) => {
  const pane = '[aria-label^="Messages in conversation"]';
  return await page.locator(pane + ' img').evaluateAll(async (els, min) => {
    const isAttach = (e) =>
      (e.getAttribute('alt') || '') === 'Open photo' ||
      /^(data|blob):/.test(e.currentSrc || e.src || '');
    const toB64 = (buf) => {
      let s = ''; const u = new Uint8Array(buf);
      for (let i = 0; i < u.length; i++) s += String.fromCharCode(u[i]);
      return btoa(s);
    };
    const seen = new Set(); const out = [];
    for (const e of els) {
      if (!isAttach(e)) continue;
      if (e.naturalWidth && e.naturalWidth < min) continue;
      const src = e.currentSrc || e.src || '';
      const key = src.length + ':' + src.slice(-48); // tail differs per image; headers collide
      if (seen.has(key)) continue; seen.add(key);
      let at = e.closest('[aria-label^="At "]');
      at = at ? at.getAttribute('aria-label') : null;
      try {
        if (src.startsWith('data:')) {
          const m = src.match(/^data:([^;,]+)[^,]*,(.*)$/s);
          out.push({ mime: m ? m[1] : 'image/jpeg', b64: m ? m[2] : '', w: e.naturalWidth, h: e.naturalHeight, at });
        } else {
          const r = await fetch(src); const b = await r.blob(); const buf = await b.arrayBuffer();
          out.push({ mime: b.type || 'image/jpeg', b64: toB64(buf), w: e.naturalWidth, h: e.naturalHeight, at });
        }
      } catch (err) {
        out.push({ error: String(err), src: src.slice(0, 48) });
      }
    }
    return out;
  }, ${min});
}`;

/**
 * Scrape the open thread by scrolling upward with the CDP mouse wheel (synthetic events
 * are ignored by the virtualized list), accumulating BOTH messages and image attachments
 * across steps until `wantMessages` newest messages are collected, the top is reached, or
 * `maxIters` is hit. The list is VIRTUALIZED (only ~20 rows + their images stay in the
 * DOM, recycled on scroll so the DOM row COUNT never grows), so a single read at the end
 * loses everything that scrolled out; we read each step and prepend newly revealed older
 * messages (longest suffix(window)==prefix(acc) run) for one chronological, gap-free order,
 * and pull each image the first time it appears (deduped by a length+tail key).
 *
 * Each step uses an ADAPTIVE in-page settle (poll until the scroll position + oldest mounted
 * label stop changing, min 250ms, capped at `waitMs`) instead of a blind fixed wait, and
 * the top is detected by the scroll container being PINNED (scrollTop unchanged across a
 * full settle) for 3 steps. On short threads this replaces a multi-second fixed tax with a
 * sub-second confirm. A productive step still moves scrollTop, so pinned-top cannot fire
 * mid-load. Returns { name, labels, images, reachedTop, iters }.
 */
export const scrapeThread = (
  wantMessages: number,
  maxIters: number,
  waitMs: number,
  min: number,
  withImages: boolean,
) => `async (page) => {
  const pane = '[aria-label^="Messages in conversation"]';
  await page.waitForSelector(pane, { timeout: 15000 }).catch(() => {});
  // Wait for the first DECRYPTED message row (e2ee plaintext lands after the pane) so the
  // caller can use a short post-goto settle instead of a long fixed sleep.
  await page.waitForSelector(pane + ' [aria-label^="At "]', { timeout: 8000 }).catch(() => {});
  const box = await page.locator(pane).boundingBox();
  if (!box) throw new Error('thread pane not rendered; open a thread first');
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  const imgsLoc = page.locator(pane + ' img');
  // Adaptive settle: poll in-page until the scroll position AND the oldest mounted label
  // both hold steady (loading finished), min 250ms, capped at \`cap\`. Returns the settled
  // scrollTop + the current label window in one IPC.
  const readState = (cap) => page.evaluate(async (a) => {
    const { paneSel, msgSel, cap } = a;
    const all = () => Array.from(document.querySelectorAll(paneSel + ' ' + msgSel));
    let sc = all()[0];
    for (; sc; sc = sc.parentElement) {
      if (sc.scrollHeight > sc.clientHeight + 4) { const oy = getComputedStyle(sc).overflowY; if (oy === 'auto' || oy === 'scroll') break; }
    }
    const top = () => sc ? sc.scrollTop : 0;
    const first = () => { const a0 = all()[0]; return a0 ? a0.getAttribute('aria-label') : null; };
    // If the scroll container can't be found, scrollTop is unusable; just wait the full cap.
    if (!sc) { if (cap > 0) await new Promise(r => setTimeout(r, cap)); return { top: 0, labels: all().map(e => e.getAttribute('aria-label')) }; }
    const t0 = Date.now(); let lt = null, lf = null, stable = 0;
    while (cap > 0 && Date.now() - t0 < cap) {
      await new Promise(r => setTimeout(r, 90));
      const ct = top(), cf = first();
      if (ct === lt && cf === lf) { if (++stable >= 2 && Date.now() - t0 > 250) break; } else stable = 0;
      lt = ct; lf = cf;
    }
    return { top: top(), labels: all().map(e => e.getAttribute('aria-label')) };
  }, { paneSel: pane, msgSel: '[aria-label^="At "]', cap });
  const grabImages = (seen) => imgsLoc.evaluateAll(async (els, args) => {
    const { min, seen } = args; const seenSet = new Set(seen);
    const isAttach = (e) => (e.getAttribute('alt') || '') === 'Open photo' || /^(data|blob):/.test(e.currentSrc || e.src || '');
    const toB64 = (buf) => { let s=''; const u=new Uint8Array(buf); for (let i=0;i<u.length;i++) s+=String.fromCharCode(u[i]); return btoa(s); };
    const out = [];
    for (const e of els) {
      if (!isAttach(e)) continue;
      if (e.naturalWidth && e.naturalWidth < min) continue;
      const src = e.currentSrc || e.src || '';
      const key = src.length + ':' + src.slice(-48);
      if (seenSet.has(key)) continue; seenSet.add(key);
      let at = e.closest('[aria-label^="At "]'); at = at ? at.getAttribute('aria-label') : null;
      try {
        if (src.startsWith('data:')) {
          const m = src.match(/^data:([^;,]+)[^,]*,(.*)$/s);
          out.push({ key, mime: m ? m[1] : 'image/jpeg', b64: m ? m[2] : '', w: e.naturalWidth, h: e.naturalHeight, at });
        } else {
          const r = await fetch(src); const b = await r.blob(); const buf = await b.arrayBuffer();
          out.push({ key, mime: b.type || 'image/jpeg', b64: toB64(buf), w: e.naturalWidth, h: e.naturalHeight, at });
        }
      } catch (err) { out.push({ key, error: String(err), src: src.slice(0, 48) }); }
    }
    return out;
  }, { min: ${min}, seen });

  const images = []; const seenKeys = [];
  const pull = async () => {
    if (!${withImages}) return;
    const got = await grabImages(seenKeys);
    for (const g of got) { if (g.key) seenKeys.push(g.key); images.push(g); }
  };

  let cur = await readState(0);
  let acc = cur.labels; let prevTop = cur.top;
  await pull();
  let iters = 0, noNew = 0;
  while (iters < ${maxIters} && acc.length < ${wantMessages} && noNew < 3) {  // 3 pinned steps => real top
    await page.mouse.wheel(0, -1800);
    const r = await readState(${waitMs});
    const win = r.labels;
    let before = [];
    if (win.length) {
      // After scrolling up, win ends with the overlap that equals acc's head; prepend the
      // strictly-older prefix. Use the longest suffix(win) == prefix(acc) RUN (not a single
      // label) so duplicate labels cannot pick a wrong anchor and drop/duplicate messages.
      let L = 0; const maxL = Math.min(win.length, acc.length);
      for (let k = maxL; k >= 1; k--) {
        let ok = true;
        for (let i = 0; i < k; i++) { if (win[win.length - k + i] !== acc[i]) { ok = false; break; } }
        if (ok) { L = k; break; }
      }
      if (L > 0) before = win.slice(0, win.length - L);
      else { const accSet = new Set(acc); before = win.filter(l => !accSet.has(l)); }
    }
    await pull();
    // Older revealed => keep going. Else: only treat as top when the scroll is PINNED
    // (scrollTop did not move); a moved scroll with no new content is still settling.
    if (before.length) { acc = before.concat(acc); noNew = 0; }
    else if (r.top === prevTop) noNew++;
    else noNew = 0;
    prevTop = r.top;
    iters++;
  }
  const reachedTop = noNew >= 3;
  const name = await page.locator(pane).first().getAttribute('aria-label')
    .then(s => (s || '').replace(/^Messages in conversation (with|titled) /, '').trim() || null)
    .catch(() => null);
  return { name, labels: acc, images, reachedTop, iters };
}`;

/**
 * Scroll the inbox rail downward, ACCUMULATING conversation rows across steps (the rail is
 * virtualized like the thread pane, so a single read at the end returns only the last
 * viewport), until `wantThreads` unique threads are collected, the bottom is reached, or
 * `maxIters` is hit. Rows are deduped by href in rail order (newest first). The rail's
 * scroll container is NOT an overflow:auto/scroll ancestor of [role=grid] (its scrollTop is
 * unreadable, unlike the thread pane), so the bottom is detected by the UNIQUE-HREF count
 * not growing for 8 consecutive steps rather than by scroll position. Throws if the rail
 * never renders (login wall / checkpoint / selector change) so the caller fails loud
 * instead of archiving nothing. Returns [{ href, name }].
 */
export const railLoader = (
  wantThreads: number,
  maxIters: number,
  waitMs: number,
) => `async (page) => {
  const grid = '[role=grid]';
  await page.waitForSelector(grid + ' [role=row]', { timeout: 20000 }); // login/checkpoint => throw
  const box = await page.locator(grid).boundingBox();
  if (box) await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  const read = () => page.evaluate((g) => Array.from(document.querySelectorAll(g + ' [role=row]')).map(r => {
    const a = r.querySelector('a[role=link][href*="/messages/"]') || r.querySelector('a[role=link]');
    const href = a && a.getAttribute('href');
    return { name: a && (a.getAttribute('aria-label') || (a.textContent || '').trim()), href };
  }).filter(x => x.name && x.href && x.href.indexOf('/messages/') >= 0), grid);
  const acc = new Map();   // href -> name; insertion order = rail order (newest first)
  const absorb = (list) => { for (const x of list) if (!acc.has(x.href)) acc.set(x.href, x.name); };
  absorb(await read());
  let iters = 0, noGrow = 0;
  while (iters < ${maxIters} && acc.size < ${wantThreads} && noGrow < 8) {  // 8 steps w/o a new href => bottom
    const before = acc.size;
    await page.mouse.wheel(0, 1400);
    await page.waitForTimeout(${waitMs});  // rail scrollTop is unreadable; use a fixed settle
    absorb(await read());
    if (acc.size > before) noGrow = 0; else noGrow++;
    iters++;
  }
  return [...acc].map(([href, name]) => ({ href, name }));
}`;

/**
 * Parse an `At <date>, <Sender>: <text>` aria-label into parts (best-effort). Photo /
 * sticker / call messages omit the `: <text>` ("At 10:56 PM, Frederik"); those parse with
 * a sender and an empty text (NOT dropped, since they carry attachments).
 */
export function parseLabel(label: string): {
  at: string | null;
  sender: string | null;
  text: string;
} {
  let m = label.match(/^At (.*), ([^,]+?): ([\s\S]*)$/);
  if (m) return { at: m[1], sender: m[2], text: m[3] };
  m = label.match(/^At (.*), ([^,]+)$/);
  if (m) return { at: m[1], sender: m[2], text: "" };
  return { at: null, sender: null, text: label.replace(/^At /, "") };
}

/**
 * Best-effort ABSOLUTE timestamp (ISO) for an FB `at` string. Facebook only renders a full
 * date on older messages; recent ones are RELATIVE ("3:03 AM", "Yesterday at 5 PM", "Mon at
 * 2 PM"), so without anchoring you cannot tell a message sent today from one sent a year ago
 * (both can read "3:03 AM" depending on age). Relative forms are resolved against `now` (the
 * SYNC time, since FB renders them relative to the moment of viewing). Returns ISO or null.
 *   "June 10, 2025, 3:27 PM" -> parsed directly
 *   "3:03 AM" / "11:35 AM"   -> today at that time
 *   "Yesterday at 5 PM"      -> now - 1 day
 *   "Mon at 2 PM" / weekday  -> most recent past occurrence of that weekday (<= 7d)
 */
export function resolveAt(at: string | null, now: Date = new Date()): string | null {
  if (!at) return null;
  const s = at.trim();
  const parseTime = (t: string): { h: number; m: number } | null => {
    const mt = t.match(/(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?/i);
    if (!mt) return null;
    let h = +mt[1];
    const ap = mt[3]?.toUpperCase();
    if (ap === "PM" && h < 12) h += 12;
    if (ap === "AM" && h === 12) h = 0;
    return { h, m: mt[2] ? +mt[2] : 0 };
  };
  const withTime = (base: Date, hm: { h: number; m: number }) => {
    const x = new Date(base);
    x.setHours(hm.h, hm.m, 0, 0);
    return x.toISOString();
  };
  // Full-date form (contains a 4-digit year): let the engine parse it; tolerate the comma
  // FB puts between the year and the time ("June 10, 2025, 3:27 PM").
  if (/\d{4}/.test(s)) {
    const direct = Date.parse(s);
    if (!Number.isNaN(direct)) return new Date(direct).toISOString();
    const alt = Date.parse(s.replace(/,(\s*\d{1,2}:\d{2})/, "$1"));
    if (!Number.isNaN(alt)) return new Date(alt).toISOString();
    return null;
  }
  // Time-only => today.
  if (/^\d{1,2}:\d{2}\s*(AM|PM)?$/i.test(s)) {
    const hm = parseTime(s);
    return hm ? withTime(now, hm) : null;
  }
  // Yesterday at <time>.
  let m = s.match(/^Yesterday(?:\s+at)?\s+(.+)$/i);
  if (m) {
    const hm = parseTime(m[1]);
    if (!hm) return null;
    const d = new Date(now);
    d.setDate(d.getDate() - 1);
    return withTime(d, hm);
  }
  // Weekday at <time> (e.g. "Mon at 2 PM", "Monday at 2 PM") => most recent past weekday.
  const days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
  m = s.match(/^([A-Za-z]{3,9})\s+at\s+(.+)$/i);
  if (m) {
    const idx = days.indexOf(m[1].toLowerCase().slice(0, 3));
    const hm = parseTime(m[2]);
    if (idx >= 0 && hm) {
      const d = new Date(now);
      let back = (now.getDay() - idx + 7) % 7;
      if (back === 0) back = 7;
      d.setDate(d.getDate() - back);
      return withTime(d, hm);
    }
  }
  return null;
}

/** File extension for an image mime, defaulting sensibly for image/* and unknowns. */
export const extFor = (mime: string): string =>
  EXT[mime] ?? (mime?.startsWith("image/") ? mime.slice(6).split("+")[0] : "jpg");

export const EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
};

/** Thread id + kind (e2ee | t) from a `/messages/...` href. */
export function threadKey(href: string): { id: string; kind: "e2ee" | "t" } | null {
  const m = href.match(/\/messages\/(e2ee\/t|t)\/([^/?#]+)/);
  if (!m) return null;
  return { id: m[2], kind: m[1].startsWith("e2ee") ? "e2ee" : "t" };
}

export const sha256hex = (buf: Uint8Array | ArrayBuffer) =>
  new Bun.CryptoHasher("sha256").update(buf as any).digest("hex");
