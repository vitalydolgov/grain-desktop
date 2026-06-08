import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var preferences = DisplayPreferences.default

    var body: some View {
        TabView {
            SettingsPlanTab()
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(
                menuBarFormat: $preferences.menuBarLabelFormat
            )
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .background(FloatingWindowConfigurator(keepOnTop: true))
        .task { preferences = settings.preferences }
        .onChange(of: preferences) { saveDisplay() }
    }

    private func saveDisplay() {
        settings.preferences = preferences
        Task {
            try? await settings.display.save(preferences)
        }
    }
}
