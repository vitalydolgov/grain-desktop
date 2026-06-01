# Grain (desktop)

A macOS menubar interval timer app. Tracks focus and break sessions with a configurable work/break cadence. Built on top of the [Grain](https://github.com/vitalydolgov/grain) library, which provides the domain model, application logic and runtime.

## Architecture

The app follows Domain-Driven Design with three layers. Dependencies point inward: **Presentation** depends on **Application**, Application depends on **Domain**. Domain has no outward dependencies.

```mermaid
flowchart TD
    P[Presentation\n<i>SwiftUI</i>]
    B[Runtime Proxy\n<i>@MainActor</i>]
    U[Persistence\n<i>UserDefaults</i>]

    subgraph ROW[" "]
        A[Application\n<i>Commands + Runtime</i>]
        D[Domain]
    end

    P --> B --> A --> D
    U --> A
```

The Grain library (at `Core/`) owns the Application and Domain layers. This repository is the Presentation layer only — SwiftUI views and `RuntimeProxy`, which bridges the actor-based runtime to  `@Observable` system on the main actor.

## Building

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project file, and the Grain library is included as a git submodule at `Core/`.

```sh
# Initialize submodule
git submodule update --init

# Generate project
xcodegen generate

# Open in Xcode
open GrainDesktop.xcodeproj
```
