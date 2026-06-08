---
name: squash
description: Squashes all commits on the branch into one, generating a commit message from the combined diff.
when_to_use: when the user wants to squash the current branch
---

Analyze all commits on the current branch and produce a single-line commit message suitable for a squash merge — no body, no bullet points, no explanation.

Steps:
1. Run !`git merge-base HEAD main` to find the branch point, then !`git diff <merge-base> HEAD` to see the full diff of all branch commits combined.
2. Run !`git log --oneline <merge-base>..HEAD` to read the individual commit messages for context.
3. Run !`git log --oneline -10 main` to learn the commit style used in this repo.
4. Derive a concise imperative-mood summary (≤72 characters) that captures the *what and why* of the combined change.

Output the commit message line and ask the user to confirm.

If the user confirms, proceed with the squash: run !`git reset --soft <merge-base>` to fold all branch commits into the index, then commit with the confirmed message.
