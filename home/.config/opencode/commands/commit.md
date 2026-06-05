---
description: Commit staged changes with conventional commit message
model: github-copilot/claude-haiku-4.5
subtask: true
---

Arguments: $ARGUMENTS

Commit all staged changes with a concise conventional commit message.

## Current state

Staged changes:
!`git diff --cached --stat`

Staged diff (modified files only, zero context):
!`git diff --cached -U0 --no-ext-diff --diff-filter=M`

Working tree:
!`git status --short`

Recent commits (for style reference):
!`git log --oneline -5`

## Rules

- If the staged diff above is empty, ask the user what to stage. Do NOT auto-stage with `git add -A`.
- Analyze the staged diff and write a single-line conventional commit message: `type(scope): description`
  - Types: feat, fix, refactor, chore, docs, style, test, ci, build, perf
  - Scope is optional, use it when changes are focused on one area
  - Description should be lowercase, imperative, no period, max 72 chars
- The commit message MUST be a single line. No body, no bullet points, no multi-line descriptions.
- Run `git commit -m "message"` — do NOT ask for confirmation.
- If the Arguments line above contains `push` or `--push`, also run `git push` after the commit succeeds.
