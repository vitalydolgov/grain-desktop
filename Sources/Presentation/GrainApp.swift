import SwiftUI
import GrainDomain
import GrainApplication

@main
struct GrainApp: App {
    @State private var settings = TimerSettings(store: UserDefaultsSettingsStore())
    @State private var timerRuntime = RuntimeProxy()

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
                .environment(timerRuntime)
        } label: {
            MenuBarView()
                .environment(timerRuntime)
                .task { timerRuntime.plan = await settings.load() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings) { timerRuntime.plan = $0 }
                .environment(timerRuntime)
        }
    }
}
