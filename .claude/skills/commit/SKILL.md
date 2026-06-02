---
name: commit
description: Commit changes following this project's commit rules
effort: low
---

1. **Message format**: single short line, no description body, no bullet points, no co-author footers.
2. **CLAUDE.md**: if it is the only changed file, use exactly `Update CLAUDE.md`. Otherwise stage and commit it silently alongside the other changes — do not mention it in the message.
3. **Core/ submodule**: if any `Core/` files changed, commit inside Core first, then commit the submodule pointer in the parent repo as a separate commit with message `Bump core`. Never commit mobile-layer changes before the Core commit.

Determine what is staged/unstaged, apply the rules above, and commit. Do not push.
