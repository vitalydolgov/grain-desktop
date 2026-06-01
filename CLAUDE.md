# Grain (desktop)

A macOS menubar interval timer app built on top of the [Grain](https://github.com/vitalydolgov/grain) library, which provides the domain model, application logic and runtime.

## Architecture

The app follows Domain-Driven Design across four layers, dependencies pointing inward:

- **Presentation** — SwiftUI views and `RuntimeProxy`, which bridges the actor-based runtime to `@Observable` on the main actor
- **Persistence** — settings storage backed by UserDefaults
- **Application** — commands and runtime from the Grain library (`GrainApplication`)
- **Domain** — aggregates and events from the Grain library (`GrainDomain`)

Presentation and Persistence are independent — both depend on Application, but not on each other. Application depends on Domain for the core model. Domain has no dependencies.

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

Use short, descriptive commit messages with no body, e.g. `Add timer reset button`.

If `Core/` changes, commit the updated submodule pointer with message "Bump core":

```sh
git add Core
git commit -m "Bump core"
```

