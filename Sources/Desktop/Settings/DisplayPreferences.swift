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

    init(menuBarLabelFormat: MenuBarLabelFormat, appearance: Appearance) {
        self.menuBarLabelFormat = menuBarLabelFormat
        self.appearance = appearance
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        menuBarLabelFormat = try container.decodeIfPresent(MenuBarLabelFormat.self, forKey: .menuBarLabelFormat)
            ?? Self.default.menuBarLabelFormat
        appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance)
            ?? Self.default.appearance
    }
}
