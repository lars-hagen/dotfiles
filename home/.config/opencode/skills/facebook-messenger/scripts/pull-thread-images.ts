#!/usr/bin/env bun
/**
 * Pull attached images from the Facebook Messenger thread that is CURRENTLY OPEN
 * in a playwright-cli session, save the originals to disk, and print a JSON manifest.
 *
 * Works headless: it drives the same `bunx @playwright/cli -s=<session> run-code` you
 * already use, so point it at a persistent-profile session (e.g. -s=fb). It does NOT
 * navigate; open the thread (and optionally run the reading.md history loader to back-
 * fill older messages) first, so only the loaded range is pulled.
 *
 * Why a two-stage design: run-code is sandboxed (no fs/process/require), so stage 1
 * extracts decrypted bytes in-page as base64, stage 2 (this process) writes the files.
 * e2ee attachments render inline as `data:` URIs (parsed directly; fetching a data: URL
 * is CSP-blocked) or as `blob:`/`https` (fetched in-page with session creds). Avatars
 * (https profile pics) and emoji (emoji.php, 32x32) are filtered out.
 *
 * Usage:
 *   bun pull-thread-images.ts [--session fb] [--out DIR] [--limit N] [--min PX]
 *   --session  playwright-cli session name (default: chrome)
 *   --out      output dir (default: $TMPDIR/fb-images/<timestamp>)
 *   --limit    keep only the most recent N images (default: all loaded)
 *   --min      skip images whose natural width < PX (default: 64)
 */

import { imageExtractor, runCode, EXT } from "./lib/extract";

const args = process.argv.slice(2);
const opt = (name: string, def?: string) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};

const session = opt("session", "chrome")!;
const limit = opt("limit") ? parseInt(opt("limit")!, 10) : 0;
const min = parseInt(opt("min", "64")!, 10);
const out =
  opt("out") ??
  `${process.env.TMPDIR ?? "/tmp"}/fb-images/${Date.now()}`.replace(/\/+/g, "/");

let data: any[];
try {
  data = await runCode(session, imageExtractor(min));
} catch (e) {
  console.error(String(e), "\nIs the thread open in session", session, "?");
  process.exit(1);
}

let items = data.filter((d) => !d.error);
const errors = data.filter((d) => d.error);
if (limit > 0 && items.length > limit) items = items.slice(-limit);

const manifest: any[] = [];
let i = 0;
for (const it of items) {
  const file = `${out}/img-${++i}.${EXT[it.mime] ?? "bin"}`;
  await Bun.write(file, Buffer.from(it.b64, "base64"));
  manifest.push({ file, mime: it.mime, w: it.w, h: it.h, at: it.at });
}

console.log(JSON.stringify({ out, count: manifest.length, images: manifest, errors }, null, 2));
