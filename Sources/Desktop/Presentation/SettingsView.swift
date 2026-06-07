import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        TabView {
            SettingsPlanTab()
                .tabItem { Label("Plan", systemImage: "timer") }

            SettingsAppearanceTab(
                menuBarFormat: $settings.preferences.menuBarLabelFormat,
                appearance: $settings.preferences.appearance
            )
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .background(FloatingWindowConfigurator(keepOnTop: true))
        .onChange(of: settings.preferences) { saveDisplay() }
    }

    private func saveDisplay() {
        Task {
            try? await settings.display.save(settings.preferences)
        }
    }
}
