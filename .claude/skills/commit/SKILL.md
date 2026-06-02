---
name: commit
description: Commit changes following this project's commit rules
effort: low
---

1. **Message format**: single short line, no description body, no bullet points, no co-author footers.
2. **CLAUDE.md**: if it is the only changed file, use exactly `Update CLAUDE.md`. Otherwise stage and commit it silently alongside the other changes — do not mention it in the message.
3. **Submodules**: if a submodule has uncommitted changes, commit inside it first, then commit the submodule pointer alone in the parent repo using `git commit <path> -m "Bump <name>"` (path-only form so pre-staged files are not included). Other parent-repo changes go in a further separate commit.

Determine what is staged/unstaged, apply the rules above. Before committing, output each proposed commit message as a plain line prefixed with `→ ` so the user can inspect them, then proceed to commit. Do not push.
