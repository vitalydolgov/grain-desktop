import SwiftUI
import GrainDomain
import GrainApplication
import GrainComponents

@main
struct GrainDesktopApp: App {
    @State private var settings = AppSettings(
        plan: PlanSettings(store: UserDefaultsPlanSettingsStore()),
        display: DisplaySettings(store: UserDefaultsDisplaySettingsStore()),
        runtimeState: RuntimeStateSettings(store: UserDefaultsRuntimeStateStore())
    )
    @State private var timerRuntime = RuntimeProxy()
    @State private var theme = AppTheme(DesktopThemeFactory())

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
                    try? await DesktopNotification.requestAuthorization()
                    if let saved = await settings.runtimeState.load() {
                        await settings.runtimeState.clear()
                        timerRuntime.restore(from: saved)
                    }
                }
                .task {
                    for await intent in timerRuntime.intents() {
                        DesktopNotification.realize(intent: intent)
                    }
                }
                .onChange(of: timerRuntime.status) { _, _ in
                    saveRuntimeState()
                }
                .onChange(of: timerRuntime.currentIndex.index) { _, _ in
                    saveRuntimeState()
                }
        }
        .menuBarExtraStyle(.menu)

        Window("Floating Timer", id: "floating-timer") {
            Group {
                if #available(macOS 26.0, *) {
                    GlassFloatingTimerView()
                } else {
                    FloatingTimerView()
                }
            }
            .environment(timerRuntime)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(timerRuntime)
                .environment(settings)
                .appTheme(theme)
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
