import Foundation
import GrainDomain

actor UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private let key = "com.github.vitalydolgov.grain.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> SessionPlan? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(SessionPlan.self, from: data)
    }

    func save(_ plan: SessionPlan) async throws {
        let data = try JSONEncoder().encode(plan)
        defaults.set(data, forKey: key)
    }
}
