import GrainApplication

protocol RuntimeStateStore: Sendable {
    func load() async throws -> RuntimeState?
    func save(_ state: RuntimeState) async throws
    func clear() async
}

struct RuntimeStateSettings: Sendable {
    private let store: any RuntimeStateStore

    init(store: any RuntimeStateStore) {
        self.store = store
    }

    func load() async -> RuntimeState? {
        try? await store.load()
    }

    func save(_ state: RuntimeState) async throws {
        try await store.save(state)
    }

    func clear() async {
        await store.clear()
    }
}
