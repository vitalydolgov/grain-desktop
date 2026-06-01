import Foundation

actor UserDefaultsDisplaySettingsStore: DisplaySettingsStore {
    private let defaults: UserDefaults
    private let key = "com.github.vitalydolgov.grain.displaySettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> MenuBarLabelFormat? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(MenuBarLabelFormat.self, from: data)
    }

    func save(_ format: MenuBarLabelFormat) async throws {
        let data = try JSONEncoder().encode(format)
        defaults.set(data, forKey: key)
    }
}
