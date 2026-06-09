enum MenuBarMode: String, Codable, CaseIterable, Sendable {
    case time
    case minutes
    case icon
}

struct DisplayPreferences: Codable, Sendable, Equatable {
    var menuBarMode: MenuBarMode

    static let `default` = DisplayPreferences(menuBarMode: .icon)
}
