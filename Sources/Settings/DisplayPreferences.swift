enum MenuBarLabelFormat: String, Codable, CaseIterable, Sendable {
    case time
    case icon
}

struct PhaseLabels: Codable, Sendable {
    var nameA: String
    var nameB: String

    static let `default` = PhaseLabels(nameA: "Work", nameB: "Break")
}

struct DisplayPreferences: Codable, Sendable {
    var menuBarLabelFormat: MenuBarLabelFormat
    var phaseLabels: PhaseLabels

    static let `default` = DisplayPreferences(
        menuBarLabelFormat: .time,
        phaseLabels: .default
    )
}
