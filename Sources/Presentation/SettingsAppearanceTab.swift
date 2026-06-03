import SwiftUI
import GrainDomain

struct SettingsAppearanceTab: View {
    @Binding var menuBarFormat: MenuBarLabelFormat

    var body: some View {
        Form {
            Section {
                Picker("Menu bar", selection: $menuBarFormat) {
                    Text("Time").tag(MenuBarLabelFormat.time)
                    Text("Icon").tag(MenuBarLabelFormat.icon)
                }
            }
        }
        .formStyle(.grouped)
    }
}
