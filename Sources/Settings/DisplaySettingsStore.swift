protocol DisplaySettingsStore: Sendable {
    func load() async throws -> MenuBarLabelFormat?
    func save(_ format: MenuBarLabelFormat) async throws
}
