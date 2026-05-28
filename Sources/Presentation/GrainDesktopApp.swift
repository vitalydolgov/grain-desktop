import SwiftUI
import GrainDomain
import GrainApplication

@main
struct GrainDesktopApp: App {
    @State private var timerService = TimerService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraView()
                .environment(timerService)
        } label: {
            MenuBarView()
                .environment(timerService)
        }
        .menuBarExtraStyle(.window)

        SwiftUI.Settings {
            SettingsView()
                .environment(timerService)
        }
    }
}

