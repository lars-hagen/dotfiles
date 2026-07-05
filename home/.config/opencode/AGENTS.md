# Global Agent Rules

## Core behavior

- **STOP** before any visible external write under my identity (comments, tickets, messages, PR reviews, issue updates) and get explicit approval.
- Prefer the smallest maintainable diff that fits existing patterns. No new dependencies or architecture without approval.
- Do not leave placeholders, stubs, TODOs, or FIXME notes unless explicitly asked.
- Verify changes: run relevant tests or linters before reporting back. On tool failure, retry once; if still blocked, report the exact error with what completed vs. what remains.
- Be concise; no em dashes, no `--` as dashes, no emojis. Use periods or semicolons.
- Drop filler (just/really/basically/actually), pleasantries, hedging. Fragments OK. Technical substance exact; only fluff dies.
- Go quiet between tool round trips: no narration between edits, no status chatter ("Great! now let me..."), no restating what just happened. Say the plan once before a batch and the result once after.
- **Danish text**: use æ ø å, never the digraphs ae oe aa. Applies to all written output.
- Commit messages: single line, conventional commits (`type: short description`). Never multi-line. No body, no bullet list, no trailing paragraphs. If the change is too large for one line, the change is too large for one commit.

## Context gathering

- Front-load reads. When the brief names files, paths, or a bounded target set, batch-read all of them before reasoning. Over-read rather than under-read; one fat call beats two thin ones.
- Avoid repeated reads or searches. Once a candidate dir is identified, scope follow-up there; do not re-grep the parent. Defer to your agent-specific discovery budget for cadence and caps.

## Environment & search

- macOS (Apple Silicon), zsh. Packages via Homebrew.
- Discovery: native tools first, always. Map intent to tool:
  - find files by name/path → `glob` (e.g. `**/*.ts`, `src/**/handler*`)
  - search file contents → `grep` (regex; filter with `include`)
  - list directory → `list`
  - read known file → `read`
  Bash is the fallback, not the default. Reach for it only when native cannot express the query: pipes, composed AND/NOT, multiline regex.
- `fd` and `rg`/ripgrep are both installed. Still prefer the native `grep` tool for content search; reach for `rg`/`fd` only when shelling out for pipes or composed queries.
