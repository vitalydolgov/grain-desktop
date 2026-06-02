import SwiftUI
import GrainDomain

@main
struct GrainApp: App {
    @State private var settings = GrainAppSettings(
        timer: TimerSettings(store: UserDefaultsTimerSettingsStore()),
        display: DisplaySettings(store: UserDefaultsDisplaySettingsStore())
    )
    @State private var timerRuntime = RuntimeProxy()
    @State private var menuBarFormat: MenuBarLabelFormat = .time
    @State private var phaseLabels: PhaseLabels = .default

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
                .environment(timerRuntime)
                .environment(\.phaseLabels, phaseLabels)
        } label: {
            MenuBarView()
                .environment(timerRuntime)
                .environment(\.menuBarLabelFormat, menuBarFormat)
                .task {
                    timerRuntime.plan = await settings.timer.load()
                    let prefs = await settings.display.load()
                    menuBarFormat = prefs.menuBarLabelFormat
                    phaseLabels = prefs.phaseLabels
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                settings: settings,
                onSave: { timerRuntime.plan = $0 },
                onDisplaySave: { menuBarFormat = $0.menuBarLabelFormat; phaseLabels = $0.phaseLabels }
            )
            .environment(timerRuntime)
        }
    }
}
