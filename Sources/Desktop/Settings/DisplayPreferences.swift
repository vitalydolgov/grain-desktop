enum MenuBarLabelFormat: String, Codable, CaseIterable, Sendable {
    case time
    case minutes
    case icon
}

struct DisplayPreferences: Codable, Sendable, Equatable {
    var menuBarLabelFormat: MenuBarLabelFormat

    static let `default` = DisplayPreferences(menuBarLabelFormat: .time)
}
