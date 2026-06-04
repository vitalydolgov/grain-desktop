import Observation
import GrainDomain
import GrainApplication

// MARK: Stores

protocol TimerSettingsStore: Sendable {
    func load() async throws -> SessionPlan?
    func save(_ plan: SessionPlan) async throws
}

protocol DisplaySettingsStore: Sendable {
    func load() async throws -> DisplayPreferences?
    func save(_ preferences: DisplayPreferences) async throws
}

// MARK: Facades

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
    let timer: TimerSettings
    let display: DisplaySettings
    let runtimeState: RuntimeStateSettings
    var preferences: DisplayPreferences = .default

    init(timer: TimerSettings, display: DisplaySettings, runtimeState: RuntimeStateSettings) {
        self.timer = timer
        self.display = display
        self.runtimeState = runtimeState
    }
}
