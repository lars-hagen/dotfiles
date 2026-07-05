#!/usr/bin/env bun
/**
 * Sync a local, idempotent archive of your recent Facebook Messenger conversations.
 *
 * One run sweeps the last N conversations from the inbox rail and, per thread, pulls the
 * last N messages plus their image attachments to disk. Re-running MERGES: new threads /
 * forced threads get a deep backfill; already-cached threads get a shallow pass that only
 * appends messages newer than what is stored. Images are deduped by content hash.
 *
 * Requires the persistent-profile session (e2ee keys live in the profile, not cookies):
 *   PROFILE="$HOME/.local/share/fb/profile"
 *   bunx @playwright/cli -s=fb open --persistent --profile="$PROFILE" "https://www.facebook.com/messages/t/"
 *   bun sync-cache.ts --session fb
 *
 * Data is decrypted plaintext + photos: it is written OUTSIDE this git-tracked skill, to a
 * 700 dir alongside the profile. Default root: ${XDG_DATA_HOME:-$HOME/.local/share}/fb/cache
 *
 *   cache/
 *     index.json                       [{id,name,kind,url,lastSynced,msgCount,imgCount}]
 *     threads/<id>/meta.json           {id,name,url,kind,lastSynced,oldestAt,newestAt,...}
 *     threads/<id>/messages.json       [{label,at,sender,text,images:["images/<sha>.jpg"]}]
 *     threads/<id>/images/<sha256>.ext
 *
 * Flags:
 *   --session NAME   playwright-cli session (default: fb)
 *   --threads N      max conversations to sweep (default: 100)
 *   --messages N     max messages to backfill per thread on a deep pass (default: 100)
 *   --images BOOL    pull image attachments (default: true; pass --images false to skip)
 *   --min PX         skip images narrower than PX (default: 64)
 *   --root DIR       cache root (default: XDG path above)
 *   --delay MS       pause between threads, +-50% jitter (default: 1500)
 *   --force          deep re-pull every thread, not just new ones
 *   --new-only       skip threads already cached (no goto); fast breadth widening. Pair
 *                    with a high --threads to reach uncached conversations deeper in the
 *                    rail, and to resume an interrupted sweep without re-touching done ones.
 *   --only SUBSTR    only sync threads whose name contains SUBSTR (case-insensitive); sync a
 *                    single person without touching the rest of the inbox.
 */
import { mkdirSync, chmodSync, existsSync, readFileSync, writeFileSync, renameSync } from "node:fs";
import { join, dirname } from "node:path";
import {
  runCode,
  cli,
  scrapeThread,
  railLoader,
  parseLabel,
  resolveAt,
  threadKey,
  extFor,
  sha256hex,
} from "./lib/extract";
import { buildViews } from "./organize-cache";

const args = process.argv.slice(2);
const opt = (n: string, d?: string) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};
const flag = (n: string) => args.includes(`--${n}`);

const session = opt("session", "fb")!;
const posInt = (name: string, def: string) => {
  const v = Number(opt(name, def));
  if (!Number.isInteger(v) || v <= 0) {
    console.error(`--${name} must be a positive integer`);
    process.exit(2);
  }
  return v;
};
const wantThreads = posInt("threads", "100");
const wantMessages = posInt("messages", "100");
const min = posInt("min", "64");
const delay = posInt("delay", "1500");
const withImages = opt("images", "true") !== "false";
const force = flag("force");
const newOnly = flag("new-only");
const only = opt("only")?.toLowerCase();
const HOME = process.env.HOME!;
const defaultRoot = `${process.env.XDG_DATA_HOME ?? join(HOME, ".local/share")}/fb/cache`;
const root = opt("root", defaultRoot)!;

const sleep = (ms: number) => Bun.sleep(ms);
const jitter = () => delay + Math.floor((Math.random() - 0.5) * delay);
const readJSON = (p: string, def: any) => (existsSync(p) ? JSON.parse(readFileSync(p, "utf8")) : def);
// Atomic write: temp file in the same dir + rename, so an interrupted run never leaves a
// truncated/corrupt JSON in the archive.
const writeJSON = (p: string, v: any) => {
  mkdirSync(dirname(p), { recursive: true });
  const tmp = `${p}.tmp-${process.pid}`;
  writeFileSync(tmp, JSON.stringify(v, null, 2));
  renameSync(tmp, p);
};

// --- cache root (700, alongside the credential-grade profile) ---
mkdirSync(root, { recursive: true });
try {
  chmodSync(root, 0o700);
  if (root === defaultRoot) chmodSync(dirname(root), 0o700); // ~/.local/share/fb
} catch {}
const indexPath = join(root, "index.json");
const index: Record<string, any> = Object.fromEntries(
  (readJSON(indexPath, []) as any[]).map((e) => [e.id, e]),
);

type Msg = { label: string; at: string | null; ts?: string | null; sender: string | null; text: string; images?: string[] };

// --- 1. list recent conversations from the inbox rail ---
process.stderr.write(`opening inbox (session ${session})...\n`);
await cli(session, "goto", "https://www.facebook.com/messages/t/");
await sleep(1800);
const rail: { name: string; href: string }[] = await runCode(
  session,
  railLoader(wantThreads, 600, 700), // adaptive stop at the rail bottom; cap is a safety net
);
const seenHref = new Set<string>();
const threads = rail
  .filter((t) => t.href && !seenHref.has(t.href) && seenHref.add(t.href))
  .map((t) => ({ ...t, ...threadKey(t.href) }))
  .filter((t): t is { name: string; href: string; id: string; kind: "e2ee" | "t" } => !!(t as any).id)
  .filter((t) => !only || t.name.toLowerCase().includes(only))
  .slice(0, wantThreads);
process.stderr.write(`found ${threads.length} conversations\n`);
if (threads.length === 0) {
  console.error("no conversations found (login wall, checkpoint, or rail selector change?)");
  process.exit(1);
}

// --- 2. per-thread sync ---
const summary: any[] = [];
let n = 0;
for (const t of threads) {
  n++;
  const dir = join(root, "threads", t.id);
  const msgsPath = join(dir, "messages.json");
  const cached = existsSync(msgsPath);
  if (newOnly && cached && !force) {
    process.stderr.write(`[${n}/${threads.length}] ${t.name}: skip (cached, --new-only)\n`);
    summary.push({ id: t.id, name: t.name, skipped: true });
    continue; // no goto, no pacing sleep
  }
  const deep = force || !cached;
  const url = "https://www.facebook.com" + t.href;
  const tag = `[${n}/${threads.length}] ${t.name} (${t.kind})`;
  try {
    await cli(session, "goto", url);
    await sleep(600); // scrapeThread waits for the first decrypted row itself
    type Loaded = { name: string | null; labels: string[]; images: any[]; reachedTop?: boolean; iters?: number };
    let loaded: Loaded = await runCode(
      session,
      scrapeThread(deep ? wantMessages : 25, deep ? 120 : 12, deep ? 1100 : 900, min, withImages),
    );
    const name = loaded.name || t.name;
    // Keep photo/sticker messages (no ": <text>", empty text); drop only rows we cannot
    // parse at all (sender === null). `ts` anchors FB's relative timestamps to the sync time
    // so the stored history carries real, comparable dates (see resolveAt).
    const now = new Date();
    const parse = (labels: string[]): Msg[] =>
      labels
        .map((label) => {
          const p = parseLabel(label);
          return { label, ...p, ts: resolveAt(p.at, now) };
        })
        .filter((m) => m.sender !== null);
    let fresh: Msg[] = parse(loaded.labels);
    // Guard: scrapeThread throws if the pane never renders, so reaching here with zero
    // parseable messages means the message/parse selectors changed (or a locale switch).
    // Never overwrite or create an empty archive on that.
    if (fresh.length === 0) throw new Error("pane rendered but no messages parsed (selector/locale change?)");

    const existing: Msg[] = readJSON(msgsPath, []);
    // Merge key is sender+text, NOT the aria-label: labels carry relative timestamps
    // ("10:59 PM" -> "Yesterday at ..." -> a date) that mutate across days. `fresh` is the
    // newest window and is AUTHORITATIVE for the range it covers; `existing` may be older
    // history, an equal window (deep re-pull), or a superset. The overlap is the longest
    // contiguous SUFFIX of `existing` whose keys all appear in `fresh` (set membership, so a
    // single inserted/edited/duplicated message inside the window does not nuke the whole
    // overlap the way an exact suffix==prefix sequence match would), capped at fresh.length
    // so we never drop more stored history than fresh can replace. We keep existing up to
    // that boundary and append the whole fresh window.
    // Normalize the sender to its first word, lowercased: Facebook renders the same person
    // as a full name ("Frederik Borgbjerg") on the latest/standalone message but the first
    // name ("Frederik") once it groups with older ones, so a raw sender+text key for the
    // SAME message changes between scrapes (worst at the newest message, where suffix
    // matching starts) and breaks overlap detection. First-word is stable within a thread.
    const keyOf = (m: Msg) =>
      (m.sender ?? "").trim().split(/\s+/)[0].toLowerCase() + "\u0000" + m.text;
    const overlapOf = (ex: Msg[], fr: Msg[]) => {
      const fset = new Set(fr.map(keyOf));
      let s = ex.length;
      while (s > 0 && ex.length - s < fr.length && fset.has(keyOf(ex[s - 1]))) s--;
      return ex.length - s; // # of existing tail messages covered by fresh
    };
    let overlap = existing.length ? overlapOf(existing, fresh) : 0;

    // Gap guard: zero overlap with stored history means the newest stored message is not in
    // the fresh window, i.e. more new messages arrived than the (shallow) depth captured.
    // Escalate to a deep scrape before accepting a silent gap; if even deep cannot bridge
    // it, keep all data but FLAG the gap in meta.
    let escalated = false;
    if (existing.length && overlap === 0 && !deep) {
      process.stderr.write(`${tag}: shallow gap, escalating to deep\n`);
      escalated = true;
      await cli(session, "goto", url);
      await sleep(600);
      loaded = await runCode(session, scrapeThread(wantMessages, 120, 1100, min, withImages));
      fresh = parse(loaded.labels);
      if (fresh.length === 0) throw new Error("no messages parsed on deep retry");
      overlap = overlapOf(existing, fresh);
    }
    const gap = existing.length > 0 && overlap === 0;

    const messages: Msg[] = existing.slice(0, existing.length - overlap).concat(fresh);

    // Carry images forward POSITIONALLY for the replaced overlap region. A key-based carry
    // would collide for photo-only messages sharing sender+"" ; position is collision-free.
    // Only fills when the re-pull did not (e.g. --images false).
    const replacedStart = existing.length - overlap;
    for (let i = 0; i < overlap; i++) {
      const ex = existing[replacedStart + i];
      const fr = fresh[i];
      if (ex?.images?.length && !fr.images?.length) fr.images = [...ex.images];
    }

    // --- images accumulated during the scroll (scrapeThread) ---
    let newImgCount = 0;
    if (withImages) {
      const byLabel = new Map(messages.map((m) => [m.label, m]));
      for (const it of loaded.images ?? []) {
        if (it.error || !it.b64) continue;
        const buf = Buffer.from(it.b64, "base64");
        const sha = sha256hex(buf);
        const rel = `images/${sha}.${extFor(it.mime)}`;
        const abs = join(dir, rel);
        if (!existsSync(abs)) {
          mkdirSync(dirname(abs), { recursive: true });
          writeFileSync(abs, buf);
          newImgCount++;
        }
        const m = it.at ? byLabel.get(it.at) : undefined;
        if (m) {
          m.images = m.images ?? [];
          if (!m.images.includes(rel)) m.images.push(rel);
        }
      }
    }

    const imgTotal = messages.reduce((s, m) => s + (m.images?.length ?? 0), 0);
    const passName = deep || escalated ? "deep" : "shallow";
    const meta = {
      id: t.id,
      name,
      kind: t.kind,
      url,
      lastSynced: new Date().toISOString(),
      pass: passName,
      reachedTop: loaded.reachedTop ?? null, // false => stopped by cap/maxIters, not the top
      gap, // true => could not bridge to stored history; older slice may be stale/disjoint
      msgCount: messages.length,
      imgCount: imgTotal,
      oldestAt: messages[0]?.at ?? null,
      newestAt: messages[messages.length - 1]?.at ?? null,
      // Absolute timeline + who spoke last, so a follow-up can reason about recency and
      // whether the ball is in your court without re-deriving it from relative labels.
      newestTs: messages[messages.length - 1]?.ts ?? null,
      lastSender: messages[messages.length - 1]?.sender ?? null,
    };
    writeJSON(msgsPath, messages);
    writeJSON(join(dir, "meta.json"), meta);
    index[t.id] = {
      id: t.id,
      name,
      kind: t.kind,
      url,
      lastSynced: meta.lastSynced,
      msgCount: meta.msgCount,
      imgCount: meta.imgCount,
      gap,
    };
    writeJSON(indexPath, Object.values(index));
    const added = existing.length ? messages.length - existing.length : messages.length;
    process.stderr.write(
      `${tag}: ${passName} ${messages.length} msgs (+${added}), +${newImgCount} imgs${gap ? " [GAP]" : ""}\n`,
    );
    summary.push({ id: t.id, name, pass: passName, msgs: messages.length, addedMsgs: added, newImgs: newImgCount, gap });
  } catch (e) {
    process.stderr.write(`${tag}: ERROR ${String(e).slice(0, 160)}\n`);
    summary.push({ id: t.id, name: t.name, error: String(e).slice(0, 160) });
  }
  if (n < threads.length) await sleep(jitter());
}

// Regenerate the human-readable views (by-name/ symlinks + index.md) so the cache is
// browsable without ever touching the numeric thread IDs.
try {
  buildViews(root);
} catch (e) {
  process.stderr.write(`view rebuild failed: ${String(e).slice(0, 160)}\n`);
}

console.log(
  JSON.stringify(
    {
      root,
      threads: summary.length,
      ok: summary.filter((s) => !s.error && !s.skipped).length,
      skipped: summary.filter((s) => s.skipped).length,
      errors: summary.filter((s) => s.error).length,
      results: summary,
    },
    null,
    2,
  ),
);
