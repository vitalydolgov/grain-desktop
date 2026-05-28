# GrainDesktop

A macOS menubar timer built on top of the [Grain](../grain) library. No persistence — state is in-memory and resets on restart.

## Architecture

The app follows Domain-Driven Design. The Grain library covers the domain and application layers; this repository only contains the presentation layer.

Three layers, dependencies pointing inward:

- **Presentation** — SwiftUI views, view models, and environment
- **Application** — use cases from the Grain library (`GrainApplication`)
- **Domain** — aggregates and events from the Grain library (`GrainDomain`)

## Conventions

### SwiftUI

- Extract non-trivial sub-views into their own private structs rather than leaving them as computed `@ViewBuilder` properties on the parent view.
- Order view properties: `@Environment` → `@State`/`@Bindable` → `@Query` → `let`.
- Order within a view struct: properties → `init` → `body` → private helpers (computed vars and methods).
- Business logic lives as private methods on the view; extract a view model only when the logic is substantial enough to warrant a separate type.

## Building

Run `xcodegen generate` whenever files are added or removed, then build:

```sh
xcodegen generate
xcodebuild build -project GrainDesktop.xcodeproj -scheme GrainDesktop \
  -destination 'platform=macOS'
```

Always run the build after every code change and fix all errors before reporting the task as done.
