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
                    ForEach(Appearance.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension Appearance {
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
