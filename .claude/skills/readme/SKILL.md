---
name: update-readme
description: Update README.md
user-invocable: false
when_to_use: whenever the user asks to update, edit, or add content to the README
---

`README.md` is a symlink to `CLAUDE.md` — apply changes to `CLAUDE.md` instead.

Keep this section structure:

1. **Introduction** — what this repo is about, in a sentence or two.
2. **Stack** — inline bold label followed by a single line, not a heading.
3. **Features** — capabilities a reader would not already infer from the introduction.
4. **Targets** — the project's actual build targets (structure, not design): one bullet per target, each with a short description.
5. **Architecture** — the underlying system design: its layers and components.
6. **Building & Testing** — how to set up the project, build, and run tests.
