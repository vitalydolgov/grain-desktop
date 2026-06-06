import SwiftUI
import GrainDomain
import GrainApplication

@main
struct GrainDesktopApp: App {
    @State private var settings = AppSettings(
        plan: PlanSettings(store: UserDefaultsPlanSettingsStore()),
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
                    if let plan = await settings.plan.load().makePlan() {
                        timerRuntime.plan = plan
                    }
                    settings.preferences = await settings.display.load()
                    NotificationService.requestAuthorization()
                    if let saved = await settings.runtimeState.load() {
                        await settings.runtimeState.clear()
                        timerRuntime.restore(from: saved)
                    }
                }
                .task {
                    for await signal in timerRuntime.signals() {
                        switch signal {
                        case .intervalCompleted(let idx):
                            let plan = timerRuntime.plan
                            guard idx.index < plan.intervals.count else { break }
                            let tag = plan.intervals[idx.index].tag
                            NotificationService.notifyPhaseCompleted(tag: tag)
                        case .sessionCompleted:
                            NotificationService.notifySessionCompleted()
                        case .sessionCompletedWhileAway:
                            NotificationService.notifySessionCompleted(whileAway: true)
                        case .sessionRestored:
                            NotificationService.notifyStateRecovered()
                        }
                    }
                }
                .task {
                    let relay = RuntimeStateRelay(publisher: RuntimeStateSync.publisher(as: .desktop))
                    await relay.transmit(states: await timerRuntime.runtimeStates())
                }
                .onChange(of: timerRuntime.status) { _, _ in
                    saveRuntimeState()
                }
                .onChange(of: timerRuntime.currentIndex.index) { _, _ in
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

    private func saveRuntimeState() {
        guard let timer = timerRuntime.timer else { return }
        let state = RuntimeState(snapshot: timer, plan: timerRuntime.plan)
        Task {
            switch timer.status {
            case .running, .paused:
                try? await settings.runtimeState.save(state)
            case .idle, .completed:
                await settings.runtimeState.clear()
            }
        }
    }
}
