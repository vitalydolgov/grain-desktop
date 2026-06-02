import Foundation

actor UserDefaultsRuntimeStateStore: RuntimeStateStore {
    private let defaults: UserDefaults
    private let key = "com.github.vitalydolgov.grain.runtimeState"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> RuntimeState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(RuntimeState.self, from: data)
    }

    func save(_ state: RuntimeState) async throws {
        let data = try JSONEncoder().encode(state)
        defaults.set(data, forKey: key)
    }

    func clear() async {
        defaults.removeObject(forKey: key)
    }
}
