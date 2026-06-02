import SwiftUI
import GrainDomain

@main
struct GrainApp: App {
    @State private var settings = GrainAppSettings(
        timer: TimerSettings(store: UserDefaultsTimerSettingsStore()),
        display: DisplaySettings(store: UserDefaultsDisplaySettingsStore()),
        runtimeState: RuntimeStateSettings(store: UserDefaultsRuntimeStateStore())
    )
    @State private var timerRuntime = RuntimeProxy()

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
                .environment(timerRuntime)
                .environment(settings)
        } label: {
            MenuBarView()
                .environment(timerRuntime)
                .environment(settings)
                .task {
                    timerRuntime.plan = await settings.timer.load()
                    settings.preferences = await settings.display.load()
                    if let saved = await settings.runtimeState.load() {
                        timerRuntime.restore(plan: saved.plan, location: saved.location,
                                             phaseStartedAt: saved.phaseStartedAt)
                    }
                }
                .onChange(of: timerRuntime.state) { _, _ in saveRuntimeState() }
                .onChange(of: timerRuntime.currentLocation) { _, _ in saveRuntimeState() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(timerRuntime)
                .environment(settings)
        }
    }

    @MainActor
    private func saveRuntimeState() {
        let state = timerRuntime.state
        let location = timerRuntime.currentLocation
        let elapsed = timerRuntime.elapsedInPhase
        let plan = timerRuntime.plan
        Task {
            switch state {
            case .running, .paused:
                guard let location else { return }
                let phaseStartedAt = Date().addingTimeInterval(-TimeInterval(elapsed.seconds))
                let runtimeState = RuntimeState(
                    plan: plan,
                    location: location,
                    phaseStartedAt: phaseStartedAt
                )
                try? await settings.runtimeState.save(runtimeState)
            case .idle, .completed:
                await settings.runtimeState.clear()
            }
        }
    }
}
