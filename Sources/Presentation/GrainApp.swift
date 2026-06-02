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
    @State private var notifications = NotificationService()

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
                    notifications.requestAuthorization()
                    if let saved = await settings.runtimeState.load() {
                        await settings.runtimeState.clear()
                        timerRuntime.restore(plan: saved.plan, location: saved.location,
                                             phaseStartedAt: saved.phaseStartedAt,
                                             wasRunning: saved.wasRunning)
                    }
                }
                .task {
                    for await signal in timerRuntime.signals {
                        switch signal {
                        case .phaseCompleted(let location):
                            let labels = settings.preferences.phaseLabels
                            let name = location.kind == .phaseA ? labels.nameA : labels.nameB
                            notifications.notifyPhaseCompleted(phaseName: name)
                        case .sessionCompleted:
                            notifications.notifySessionCompleted()
                        case .sessionCompletedWhileAway:
                            notifications.notifySessionCompleted(whileAway: true)
                        case .sessionRestored:
                            notifications.notifyStateRecovered()
                        }
                    }
                }
                .onChange(of: timerRuntime.state) { _, _ in
                    saveRuntimeState()
                }
                .onChange(of: timerRuntime.currentLocation) { _, _ in
                    saveRuntimeState()
                }
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
                    phaseStartedAt: phaseStartedAt,
                    wasRunning: state == .running
                )
                try? await settings.runtimeState.save(runtimeState)
            case .idle, .completed:
                await settings.runtimeState.clear()
            }
        }
    }
}
