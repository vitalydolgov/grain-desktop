import Foundation
import GrainApplication

private extension RuntimeStateSync.Source {
    var cloudKey: String {
        "com.github.vitalydolgov.Grain.state.\(rawValue)"
    }
}

struct CloudRuntimeStatePublisher: RuntimeStatePublisher {
    let source: RuntimeStateSync.Source

    func publish(_ state: RuntimeState) {
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(state) {
            store.set(data, forKey: source.cloudKey)
        }
        store.synchronize()
    }
}

struct CloudRuntimeStateSubscriber: RuntimeStateSubscriber {
    let states: AsyncStream<RuntimeState>

    init(source: RuntimeStateSync.Source) {
        let (states, continuation) = AsyncStream.makeStream(of: RuntimeState.self)
        self.states = states
        let key = source.cloudKey
        NSUbiquitousKeyValueStore.default.synchronize()
        if let state = Self.read(key: key) { continuation.yield(state) }
        _ = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: nil
        ) { _ in
            if let state = Self.read(key: key) { continuation.yield(state) }
        }
    }

    private static func read(key: String) -> RuntimeState? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(RuntimeState.self, from: data)
    }
}
