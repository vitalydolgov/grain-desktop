import GrainDomain

struct TimerSettings: Sendable {
    private let store: any TimerSettingsStore

    init(store: any TimerSettingsStore) {
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
