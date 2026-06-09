# Conventions

Guidelines for adding new features or modifying existing code.

## Presentation

- Extract non-trivial sub-views into their own private structs rather than computed `@ViewBuilder` properties or helper functions returning `some View` on the parent.
- Order view properties by stability, most stable first: `let` constants → `@Binding` (caller-owned) → `@Environment` (injected) → `@AppStorage`/`@State`/`@Bindable` (view-owned).
- Order within a view struct: properties → `init` → `body` → private helpers.
- Business logic lives as private methods on the view; extract a view model only when the logic is substantial enough to warrant a separate type.
- Use `@AppStorage` only for state that's local to a single view and needs no app-wide observation.
- Views do not have default values for their properties; always pass values explicitly at the call site.

## Common

- Swift 6, strict concurrency on.
- Doc comments are a single short line. No parameter or returns blocks.
- Don't add comments that restate what the code does; prefer clear names.
- Don't extract one-line helpers — inline them at the call site.
- Never use force unwrap (`!`) or force try (`try!`) — use `guard let … else { preconditionFailure(…) }` so the impossible case is explicit and loud rather than a silent crash.
- Never use `@unchecked Sendable` — if the compiler cannot verify `Sendable`, refactor to make it evident (immutable state, actor isolation) rather than suppressing the check.
