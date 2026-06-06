import Observation

protocol DisplaySettingsStore: Sendable {
    func load() async throws -> DisplayPreferences?
    func save(_ preferences: DisplayPreferences) async throws
}

struct DisplaySettings: Sendable {
    private let store: any DisplaySettingsStore

    init(store: any DisplaySettingsStore) {
        self.store = store
    }

    func load() async -> DisplayPreferences {
        do {
            return try await store.load() ?? .default
        } catch {
            return .default
        }
    }

    func save(_ preferences: DisplayPreferences) async throws {
        try await store.save(preferences)
    }
}

// MARK: Composition

@MainActor
@Observable
final class AppSettings {
    let plan: PlanSettings
    let display: DisplaySettings
    let runtimeState: RuntimeStateSettings

    init(plan: PlanSettings, display: DisplaySettings, runtimeState: RuntimeStateSettings) {
        self.plan = plan
        self.display = display
        self.runtimeState = runtimeState
    }
}
