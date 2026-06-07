import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var displayPrefs = DisplayPreferences.default

    var body: some View {
        TabView {
            SettingsPlanTab()
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(
                menuBarFormat: $displayPrefs.menuBarLabelFormat,
                appearance: $displayPrefs.appearance
            )
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .background(FloatingWindowConfigurator(keepOnTop: true))
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
