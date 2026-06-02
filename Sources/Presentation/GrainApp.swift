import SwiftUI
import GrainDomain

@main
struct GrainApp: App {
    @State private var settings = GrainAppSettings(
        timer: TimerSettings(store: UserDefaultsTimerSettingsStore()),
        display: DisplaySettings(store: UserDefaultsDisplaySettingsStore())
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
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(timerRuntime)
                .environment(settings)
        }
    }
}
