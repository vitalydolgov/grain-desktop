enum MenuBarLabelFormat: String, Codable, CaseIterable, Sendable {
    case time
    case icon
}

enum Appearance: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

struct DisplayPreferences: Codable, Sendable, Equatable {
    var menuBarLabelFormat: MenuBarLabelFormat
    var appearance: Appearance

    static let `default` = DisplayPreferences(menuBarLabelFormat: .time, appearance: .system)
}
