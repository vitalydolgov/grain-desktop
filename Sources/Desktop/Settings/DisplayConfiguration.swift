enum MenuBarMode: String, Codable, CaseIterable, Sendable {
    case time
    case minutes
    case icon
}

struct DisplayConfiguration: Codable, Sendable, Equatable {
    var menuBarMode: MenuBarMode

    static let `default` = DisplayConfiguration(menuBarMode: .icon)
}
