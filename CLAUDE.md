# Project Grain

A macOS menubar interval timer app with watchOS and iOS companions. Alternates between two phases (A and B) on a repeating cycle; the Mac and iPhone each run their own timer, while the watch runs its own timer that can optionally sync with a session running on either the Mac or the iPhone.

**Stack:** Swift 6 · SwiftUI

## Features

- **Session persistence** — quitting the app or restarting the machine doesn't lose your session; running timers fast-forward through downtime on next launch, paused timers resume at the exact elapsed time
- **Configurable cycle length** — constant, growth, or decay mode controls whether phase durations stay equal or scale across cycles
- **System notifications** on phase and session completion
- **A companion watchOS app** with independent timer control and configurable phase durations; can optionally sync with a running Mac or iPhone session
- **A companion iOS app** with independent timer control and configurable phase durations; a running iPhone session can drive a watch, the same way the Mac can

## Architecture

The app follows Domain-Driven Design with three layers, plus a **Settings** bounded context. Dependencies point inward.

The inner two layers — **Application** and **Domain** — live in the [Grain](https://github.com/vitalydolgov/grain) library, consumed as a dependency. **Presentation** and **Settings** live in this repository.

```mermaid
flowchart TD
    DP["Presentation<br/><i>macOS</i>"]
    DProxy[["Runtime Proxy<br/><i>@MainActor</i>"]]
    DP --> DProxy
    DProxy --> DGrain
    DGrain -.->|state, signals| DProxy

    S("Settings<br/><i>UserDefaults</i>")
    DP --> S

    N(["Notifications"])
    DP -.->|signals| N

    DGrain["<b>Grain</b><br/><i>Runtime</i>"]

    classDef grain fill:lightblue,stroke:steelblue
    class DGrain grain
```

Cross-device state propagation is described separately under [Synchronization](#synchronization).

### Composition

- **Presentation (desktop)** — macOS menubar UI; includes `RuntimeProxy`, which bridges the actor-based runtime to `@Observable` on the main actor
- **Settings** — a *bounded context* that owns configuration, display preferences, and session restore state
- **Presentation (watch)** — watchOS UI with full timer controls and configurable phase durations; includes `RuntimeProxy` for local control and `RuntimeSynchronizer` to optionally sync with a Mac or iPhone session
- **Presentation (iOS)** — iPhone UI with full timer controls and configurable phase durations; includes `RuntimeProxy` for local control and runs a relay that publishes its state so a watch can sync to it
- **State transport** — iCloud publisher/subscriber channels (`NSUbiquitousKeyValueStore`) that carry runtime state between devices, with a local channel for debug and the simulator. One-way — no commands flow back. See [Synchronization](#synchronization)
- **Application** and **Domain** — see the [Grain](https://github.com/vitalydolgov/grain) library

Each `RuntimeProxy` is fed by two streams from the Grain runtime:

- **state** — a fresh snapshot after every change, which every proxy unpacks to keep its observable properties in sync.
- **signals** — discrete lifecycle events the presentation layer reacts to without polling: desktop notifications, watch and iPhone haptics.

### Synchronization

The watch runs its own Grain runtime with full timer control. Optionally, it can sync with a running session on the Mac **or** the iPhone: each of those runs a **Relay** (`RuntimeStateRelay`) that carries state over iCloud in one direction, source to watch — no commands flow back.

```mermaid
flowchart TD
    subgraph macOS
        DGrain["<b>Grain</b><br/><i>Runtime</i>"]
        DRelay[["Relay<br/><i>dedup + heartbeat</i>"]]
        DGrain -.->|state| DRelay
    end

    subgraph iOS
        PGrain["<b>Grain</b><br/><i>Runtime</i>"]
        PRelay[["Relay<br/><i>dedup + heartbeat</i>"]]
        PGrain -.->|state| PRelay
    end

    Cloud(["iCloud<br/><i>key–value store</i>"])

    subgraph watchOS
        Sync[["Synchronizer<br/><i>@MainActor</i>"]]
        Choice{"Sync?"}
        WGrain["<b>Grain</b><br/><i>Runtime</i>"]
        Sync --> Choice
        Choice -.->|"accept streaming"| WGrain
        Choice -.->|decline| Sync
    end

    DRelay -.->|"publish (desktop)"| Cloud
    PRelay -.->|"publish (phone)"| Cloud
    Cloud -.->|"subscribe (both)"| Sync

    classDef grain fill:lightblue,stroke:steelblue
    class DGrain,PGrain,WGrain grain
```

Each source — the Mac and the iPhone — runs the relay over its runtime's **state** stream, publishing under its own key. The relay dedupes — it republishes only when the session status or phase location changes — and writes each surviving snapshot to iCloud's key–value store. A built-in heartbeat (every 5 seconds) re-publishes the last known state so a watch that connects late can still discover an active session.

On the watch, `RuntimeSynchronizer` subscribes to both sources and tracks a sync mode that carries the source it concerns: `.none` when nothing is active remotely, `.pending` when a running or paused session is detected (prompting "Sync with Mac?" or "Sync with iPhone?"), `.synced` after the user accepts, and `.declined` if they dismiss. The first source to go active wins the prompt; once synced, the watch follows that source until it goes idle. Only on acceptance does the synchronizer restore state into the watch's own Grain runtime; from there, the runtime's **state** stream drives the Watch `RuntimeProxy` and UI — the same streaming contract as a local session, populated remotely.

The iPhone is a peer source of the Mac, not a consumer: it publishes through the same relay so the watch can slave to either device. The iPhone itself never syncs from another device.

## Building

Generate the Xcode project from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen). Create `local.yml` in the project root for developer-specific settings such as `DEVELOPMENT_TEAM`.

```sh
xcodegen generate
```

Re-run whenever you add, remove, or rename source files.

The project generates three schemes, `GrainDesktop` (macOS), `GrainWatch` (watchOS), and `GrainPhone` (iOS).

Build the desktop app:

```sh
xcodebuild build -project GrainApp.xcodeproj -scheme GrainDesktop -destination 'platform=macOS'
```

Build the watch app:

```sh
xcodebuild build -project GrainApp.xcodeproj -scheme GrainWatch -destination 'generic/platform=watchOS Simulator'
```

Build the iOS app:

```sh
xcodebuild build -project GrainApp.xcodeproj -scheme GrainPhone -destination 'generic/platform=iOS Simulator'
```
