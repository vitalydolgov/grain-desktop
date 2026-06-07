import SwiftUI
import GrainDomain

struct SettingsAppearanceTab: View {
    @Binding var menuBarFormat: MenuBarLabelFormat
    @Binding var appearance: Appearance

    var body: some View {
        Form {
            Section {
                Picker("Menu bar", selection: $menuBarFormat) {
                    Text("Time").tag(MenuBarLabelFormat.time)
                    Text("Icon").tag(MenuBarLabelFormat.icon)
                }
                Picker("Theme", selection: $appearance) {
                    Text("System").tag(Appearance.system)
                    Text("Light").tag(Appearance.light)
                    Text("Dark").tag(Appearance.dark)
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension Appearance {
    /// SwiftUI color scheme to enforce, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
