import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(GrainAppSettings.self) private var settings
    @State private var displayPrefs = DisplayPreferences.default

    var body: some View {
        TabView {
            SettingsPlanTab(displayPrefs: $displayPrefs)
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(menuBarFormat: $displayPrefs.menuBarLabelFormat)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 400)
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
