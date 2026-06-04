import Foundation

actor UserDefaultsDisplaySettingsStore: DisplaySettingsStore {
    private let defaults: UserDefaults
    private let key = "com.github.vitalydolgov.grain.display"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> DisplayPreferences? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(DisplayPreferences.self, from: data)
    }

    func save(_ preferences: DisplayPreferences) async throws {
        let data = try JSONEncoder().encode(preferences)
        defaults.set(data, forKey: key)
    }
}
