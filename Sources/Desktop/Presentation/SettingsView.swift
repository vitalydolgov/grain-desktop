import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var displayConfiguration = DisplayConfiguration.default

    var body: some View {
        TabView {
            SettingsPlanTab()
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(
                menuBarFormat: $displayConfiguration.menuBarMode
            )
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .background(FloatingWindowConfigurator(keepOnTop: true))
        .task { displayConfiguration = settings.displayConfiguration }
        .onChange(of: displayConfiguration) { saveDisplay() }
    }

    private func saveDisplay() {
        settings.displayConfiguration = displayConfiguration
        Task {
            try? await settings.display.save(displayConfiguration)
        }
    }
}
