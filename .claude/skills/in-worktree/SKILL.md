---
name: in-worktree
description: Start a new branch in a fresh worktree
when_to_use: only when the user explicitly asks to work in a worktree
---

1. Derive the branch name from the conversation context. Ask if unclear.
2. Run `git worktree add ../grain-app-BRANCH -b BRANCH` via the Bash tool, substituting BRANCH with the actual branch name.
3. Run `cp local.yml ../grain-app-BRANCH/local.yml` via the Bash tool (same substitution).
4. Proceed with the task in the new worktree.
