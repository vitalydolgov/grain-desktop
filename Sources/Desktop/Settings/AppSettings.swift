import Observation

// MARK: Stores

protocol PlanSettingsStore: Sendable {
    func load() async throws -> PlanConfiguration?
    func save(_ configuration: PlanConfiguration) async throws
}

protocol DisplaySettingsStore: Sendable {
    func load() async throws -> DisplayPreferences?
    func save(_ preferences: DisplayPreferences) async throws
}

// MARK: Facades

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
    var preferences: DisplayPreferences = .default

    init(plan: PlanSettings, display: DisplaySettings, runtimeState: RuntimeStateSettings) {
        self.plan = plan
        self.display = display
        self.runtimeState = runtimeState
    }
}
