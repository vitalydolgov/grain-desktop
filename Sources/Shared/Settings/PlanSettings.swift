import Foundation

protocol PlanSettingsStore: Sendable {
    func load() async throws -> PlanConfiguration?
    func save(_ configuration: PlanConfiguration) async throws
}

struct PlanSettings: Sendable {
    private let store: any PlanSettingsStore

    init(store: any PlanSettingsStore) {
        self.store = store
    }

    func load() async -> PlanConfiguration {
        do {
            return try await store.load() ?? .default
        } catch {
            return .default
        }
    }

    func save(_ configuration: PlanConfiguration) async throws {
        try await store.save(configuration)
    }
}
