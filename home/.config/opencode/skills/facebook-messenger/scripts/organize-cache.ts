#!/usr/bin/env bun
/**
 * Build human-readable views of the message cache so you never touch the numeric thread IDs:
 *
 *   cache/by-name/<Conversation Name>  ->  symlink to ../threads/<id>
 *   cache/index.md                     ->  table sorted by name (msgs, imgs, type, last sync)
 *
 * `sync-cache.ts` calls buildViews() at the end of every run; you can also run this
 * standalone to regenerate the views (and tidy any leftover raw pane names) without a sync:
 *
 *   bun organize-cache.ts                 # default cache root
 *   bun organize-cache.ts --root DIR
 */
import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  rmSync,
  symlinkSync,
} from "node:fs";
import { join } from "node:path";

/** Strip a leftover raw pane label ("Messages in conversation with/titled X") to just X. */
const cleanName = (s: string, fallback: string) =>
  (s || "").replace(/^Messages in conversation (with|titled) /, "").trim() || fallback;

/** Filesystem-safe single path segment (no slashes/newlines, collapsed spaces, bounded). */
const sanitize = (s: string) =>
  s.replace(/[\/\\\n\r\t]+/g, " ").replace(/\s+/g, " ").trim().slice(0, 80);

export function buildViews(root: string): { count: number } {
  const indexPath = join(root, "index.json");
  const index: any[] = JSON.parse(readFileSync(indexPath, "utf8"));

  // Tidy names in-place and persist back to index.json + each meta.json (older entries were
  // cached before the name cleanup landed).
  for (const e of index) {
    const fixed = cleanName(e.name, e.id);
    if (fixed !== e.name) {
      e.name = fixed;
      const metaPath = join(root, "threads", e.id, "meta.json");
      try {
        const meta = JSON.parse(readFileSync(metaPath, "utf8"));
        meta.name = fixed;
        writeFileSync(metaPath, JSON.stringify(meta, null, 2));
      } catch {}
    }
  }
  writeFileSync(indexPath, JSON.stringify(index, null, 2));

  index.sort((a, b) => a.name.localeCompare(b.name, "da"));

  // Rebuild by-name/ from scratch (rmSync does not follow symlinks, so targets are safe).
  const byName = join(root, "by-name");
  rmSync(byName, { recursive: true, force: true });
  mkdirSync(byName, { recursive: true });
  const used = new Set<string>();
  for (const e of index) {
    let nm = sanitize(e.name) || e.id;
    if (used.has(nm.toLowerCase())) nm = `${nm} [${e.id.slice(-4)}]`;
    used.add(nm.toLowerCase());
    symlinkSync(join("..", "threads", e.id), join(byName, nm));
  }

  // Readable table.
  let md = `# Facebook Messenger cache\n\n`;
  md += `${index.length} conversations. Browse \`by-name/<name>/\` (symlinks); read \`by-name/<name>/messages.json\`.\n\n`;
  md += `| Name | Msgs | Imgs | Type | Last synced |\n|---|---:|---:|---|---|\n`;
  for (const e of index) {
    const when = (e.lastSynced || "").slice(0, 10);
    const flag = e.gap ? " ⚠gap" : "";
    md += `| ${e.name}${flag} | ${e.msgCount} | ${e.imgCount} | ${e.kind} | ${when} |\n`;
  }
  writeFileSync(join(root, "index.md"), md);

  return { count: index.length };
}

if (import.meta.main) {
  const args = process.argv.slice(2);
  const i = args.indexOf("--root");
  const HOME = process.env.HOME!;
  const root =
    i >= 0 && args[i + 1]
      ? args[i + 1]
      : `${process.env.XDG_DATA_HOME ?? join(HOME, ".local/share")}/fb/cache`;
  const { count } = buildViews(root);
  console.log(`organized ${count} conversations -> ${join(root, "by-name")} + index.md`);
}
