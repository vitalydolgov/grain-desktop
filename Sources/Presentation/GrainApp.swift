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
                    NotificationService.requestAuthorization()
                    if let saved = await settings.runtimeState.load() {
                        await settings.runtimeState.clear()
                        timerRuntime.restore(from: saved)
                    }
                }
                .task {
                    for await signal in timerRuntime.signals {
                        switch signal {
                        case .phaseCompleted(let location):
                            let labels = settings.preferences.phaseLabels
                            let name = location.kind == .phaseA ? labels.phaseA : labels.phaseB
                            NotificationService.notifyPhaseCompleted(phaseName: name)
                        case .sessionCompleted:
                            NotificationService.notifySessionCompleted()
                        case .sessionCompletedWhileAway:
                            NotificationService.notifySessionCompleted(whileAway: true)
                        case .sessionRestored:
                            NotificationService.notifyStateRecovered()
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
        let phaseStartedAt = timerRuntime.phaseStartedAt
        let plan = timerRuntime.plan
        Task {
            switch state {
            case .running, .paused:
                guard let location, let phaseStartedAt else { return }
                let elapsed = Duration(millis: UInt64(max(0, Date().timeIntervalSince(phaseStartedAt))) * 1000)
                let runtimeState = RuntimeState(
                    plan: plan,
                    location: location,
                    phaseStartedAt: phaseStartedAt,
                    elapsedInPhase: elapsed,
                    wasRunning: state == .running
                )
                try? await settings.runtimeState.save(runtimeState)
            case .idle, .completed:
                await settings.runtimeState.clear()
            }
        }
    }
}
