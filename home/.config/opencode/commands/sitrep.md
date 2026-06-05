---
description: Show current session context - git state, branch, recent work
---

Give a concise orientation summary so the user knows where they are.

Gather and present:
1. Git state - run `git status --short --branch` and `git stash list`.
2. Recent commits - run `git log --oneline -5`.
3. Uncommitted changes - summarize staged/unstaged files (do not dump full diffs).
4. Active branch context - note ahead/behind and merge conflicts.

Present as a compact summary under 20 lines. Do NOT make any changes.
