import GrainDomain

struct TimerSettings: Sendable {
    private let store: any SettingsStore

    init(store: any SettingsStore) {
        self.store = store
    }

    func load() async -> SessionPlan {
        do {
            return try await store.load() ?? .default
        } catch {
            return .default
        }
    }

    func save(_ plan: SessionPlan) async throws {
        try await store.save(plan)
    }
}
