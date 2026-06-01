struct DisplaySettings: Sendable {
    private let store: any DisplaySettingsStore

    init(store: any DisplaySettingsStore) {
        self.store = store
    }

    func load() async -> MenuBarLabelFormat {
        do {
            return try await store.load() ?? .time
        } catch {
            return .time
        }
    }

    func save(_ format: MenuBarLabelFormat) async throws {
        try await store.save(format)
    }
}
