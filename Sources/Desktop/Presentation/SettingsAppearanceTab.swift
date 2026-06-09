import SwiftUI

struct SettingsAppearanceTab: View {
    @Binding var menuBarFormat: MenuBarLabelFormat

    var body: some View {
        Form {
            Section {
                Picker("Menu bar", selection: $menuBarFormat) {
                    ForEach(MenuBarLabelFormat.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension MenuBarLabelFormat {
    var label: String {
        switch self {
        case .time: "Time"
        case .minutes: "Minutes"
        case .icon: "Icon"
        }
    }
}
