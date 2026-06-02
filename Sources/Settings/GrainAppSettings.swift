import GrainDomain
import Observation

// MARK: Stores

protocol TimerSettingsStore: Sendable {
    func load() async throws -> SessionPlan?
    func save(_ plan: SessionPlan) async throws
}

protocol DisplaySettingsStore: Sendable {
    func load() async throws -> DisplayPreferences?
    func save(_ preferences: DisplayPreferences) async throws
}

protocol RuntimeStateStore: Sendable {
    func load() async throws -> RuntimeState?
    func save(_ state: RuntimeState) async throws
    func clear() async
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
final class GrainAppSettings {
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
