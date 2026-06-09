import SwiftUI

struct SettingsAppearanceTab: View {
    @Binding var menuBarFormat: MenuBarMode

    var body: some View {
        Form {
            Section {
                Picker("Menu bar", selection: $menuBarFormat) {
                    ForEach(MenuBarMode.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension MenuBarMode {
    var label: String {
        switch self {
        case .time: "Time"
        case .minutes: "Minutes"
        case .icon: "Ring"
        }
    }
}
