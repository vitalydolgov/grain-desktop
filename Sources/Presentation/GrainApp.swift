import SwiftUI
import GrainDomain

@main
struct GrainApp: App {
    @State private var settings = TimerSettings(store: UserDefaultsSettingsStore())
    @State private var displaySettings = DisplaySettings(store: UserDefaultsDisplaySettingsStore())
    @State private var timerRuntime = RuntimeProxy()
    @State private var menuBarFormat: MenuBarLabelFormat = .time

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
                .environment(timerRuntime)
        } label: {
            MenuBarView()
                .environment(timerRuntime)
                .environment(\.menuBarLabelFormat, menuBarFormat)
                .task {
                    timerRuntime.plan = await settings.load()
                    menuBarFormat = await displaySettings.load()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                settings: settings,
                displaySettings: displaySettings,
                onSave: { timerRuntime.plan = $0 },
                onDisplaySave: { menuBarFormat = $0 }
            )
            .environment(timerRuntime)
        }
    }
}
