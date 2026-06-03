enum MenuBarLabelFormat: String, Codable, CaseIterable, Sendable {
    case time
    case icon
}

struct PhaseLabels: Codable, Sendable, Equatable {
    var phaseA: String
    var phaseB: String

    static let `default` = PhaseLabels(phaseA: "Work", phaseB: "Break")
}

struct DisplayPreferences: Codable, Sendable, Equatable {
    var menuBarLabelFormat: MenuBarLabelFormat
    var phaseLabels: PhaseLabels

    static let `default` = DisplayPreferences(
        menuBarLabelFormat: .time,
        phaseLabels: .default
    )
}
