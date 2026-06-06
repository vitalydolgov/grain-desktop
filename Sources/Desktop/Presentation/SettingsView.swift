import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var displayPrefs = DisplayPreferences.default

    var body: some View {
        TabView {
            SettingsPlanTab()
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(menuBarFormat: $displayPrefs.menuBarLabelFormat)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .task {
            displayPrefs = await settings.display.load()
        }
        .onChange(of: displayPrefs) { saveDisplay() }
    }

    private func saveDisplay() {
        Task {
            try? await settings.display.save(displayPrefs)
            settings.preferences = displayPrefs
        }
    }
}
