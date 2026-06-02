# Conventions

## SwiftUI

- Extract non-trivial sub-views into their own private structs rather than leaving them as computed `@ViewBuilder` properties on the parent view.
- Group view properties by stability, most stable first, so a reader sees the view's fixed contract before its volatile state: `let` constants → `@Binding` (caller-owned) → `@Environment`/`@Query` (injected, external) → `@State`/`@Bindable` (view-owned, mutable).
- Order within a view struct: properties → `init` → `body` → private helpers (computed vars and methods).
- Business logic lives as private methods on the view; extract a view model only when the logic is substantial enough to warrant a separate type.
