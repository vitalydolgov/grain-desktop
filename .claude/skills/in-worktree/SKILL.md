---
name: in-worktree
description: Start a new branch in a fresh worktree
when_to_use: only when the user explicitly asks to work in a worktree
---

1. Derive the branch name from the conversation context. Ask if unclear.
2. Run `git worktree add ../PREFIX-BRANCH -b BRANCH` via the Bash tool, substituting BRANCH with the actual branch name and PREFIX with the repo's directory name.
3. Run `cp local.yml ../PREFIX-BRANCH/local.yml` via the Bash tool (same substitution).
4. Proceed with the task in the new worktree.
