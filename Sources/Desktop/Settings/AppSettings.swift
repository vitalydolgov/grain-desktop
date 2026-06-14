import Observation

// MARK: Stores

protocol DisplaySettingsStore: Sendable {
    func load() async throws -> DisplayConfiguration?
    func save(_ preferences: DisplayConfiguration) async throws
}

// MARK: Facades

struct DisplaySettings: Sendable {
    private let store: any DisplaySettingsStore

    init(store: any DisplaySettingsStore) {
        self.store = store
    }

    func load() async -> DisplayConfiguration {
        do {
            return try await store.load() ?? .default
        } catch {
            return .default
        }
    }

    func save(_ preferences: DisplayConfiguration) async throws {
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
    var displayConfiguration: DisplayConfiguration = .default

    init(plan: PlanSettings, display: DisplaySettings, runtimeState: RuntimeStateSettings) {
        self.plan = plan
        self.display = display
        self.runtimeState = runtimeState
    }

    func load() async {
        displayConfiguration = await display.load()
    }
}
