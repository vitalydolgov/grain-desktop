import Foundation

actor UserDefaultsPlanSettingsStore: PlanSettingsStore {
    private let defaults: UserDefaults
    private let key = "com.github.vitalydolgov.grain.plan"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> PlanConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(PlanConfiguration.self, from: data)
    }

    func save(_ configuration: PlanConfiguration) async throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: key)
    }
}
