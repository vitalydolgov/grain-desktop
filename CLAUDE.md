# Grain (desktop)

A macOS menubar interval timer app built on top of the [Grain](https://github.com/vitalydolgov/grain) library, which provides the domain model, application logic and runtime.

## Architecture

The app follows Domain-Driven Design with four components. Dependencies point inward:

- **Presentation** — SwiftUI views and `RuntimeProxy`, which bridges the actor-based runtime to `@Observable` on the main actor
- **Settings** — store protocols and facades for timer configuration (`TimerSettings`) and display preferences (`DisplaySettings`); depends on Domain for shared value types
  - **Settings Persistence** — `UserDefaults`-backed implementations of the Settings store protocols
- **Application** — commands and runtime from the Grain library (`GrainApplication`)
- **Domain** — aggregates and events from the Grain library (`GrainDomain`)

Presentation depends on both Application (via `RuntimeProxy`) and Settings. Settings depends on Domain. Application depends on Domain. Domain has no dependencies.

## Conventions

### SwiftUI

- Extract non-trivial sub-views into their own private structs rather than leaving them as computed `@ViewBuilder` properties on the parent view.
- Group view properties by stability, most stable first, so a reader sees the view's fixed contract before its volatile state: `let` constants → `@Binding` (caller-owned) → `@Environment`/`@Query` (injected, external) → `@State`/`@Bindable` (view-owned, mutable).
- Order within a view struct: properties → `init` → `body` → private helpers (computed vars and methods).
- Business logic lives as private methods on the view; extract a view model only when the logic is substantial enough to warrant a separate type.

## Development

Run once after cloning:

```sh
git submodule update --init
```

Run `xcodegen generate` whenever files are added or removed:

```sh
xcodegen generate
```

Always run the build after every code change and fix all errors before reporting the task as done:

```sh
xcodebuild build -project GrainDesktop.xcodeproj -scheme GrainDesktop \
  -destination 'platform=macOS'
```

## Repository

Commit messages are a single short line — no description body.

When this file is the sole change in a commit, use `Update CLAUDE.md`. Otherwise include it silently — don't mention it in the commit message.

Edit files in `Core/` directly, commit inside `Core/`, then commit the updated submodule pointer in the parent repo as a separate commit:

```sh
git add Core && git commit -m "Bump core"
```

When a change spans both `Core/` and the mobile layer, always commit and bump `Core/` first. The mobile commit's submodule pointer must reference a committed Core state — committing mobile changes before the Core commit leaves the pointer pointing at an older revision, breaking the build for that commit.
