import Foundation
import GrainApplication

private extension RuntimeStateSync.Source {
    var localFilename: String {
        "runtimeState-\(rawValue).json"
    }
}

private enum LocalFile {
    static func url(_ filename: String) -> URL? {
        let home: URL
        #if os(watchOS) && targetEnvironment(simulator)
        guard let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return nil }
        home = URL(fileURLWithPath: hostHome)
        #elseif os(macOS)
        home = FileManager.default.homeDirectoryForCurrentUser
        #elseif os(watchOS)
        return nil
        #endif
        return home.appendingPathComponent("Library/Caches/Grain/\(filename)")
    }
}

struct LocalRuntimeStatePublisher: RuntimeStatePublisher {
    let source: RuntimeStateSync.Source

    func publish(_ state: RuntimeState) {
        guard let url = LocalFile.url(source.localFilename),
              let data = try? JSONEncoder().encode(RuntimeStateEnvelope(state)) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}

struct LocalRuntimeStateSubscriber: RuntimeStateSubscriber {
    private static let expiresAfter: TimeInterval = 10

    let states: AsyncStream<RuntimeState>

    init(source: RuntimeStateSync.Source) {
        let (states, continuation) = AsyncStream.makeStream(of: RuntimeState.self)
        self.states = states
        let filename = source.localFilename
        let expiresAfter = Self.expiresAfter
        Task {
            var last: Data?
            while !Task.isCancelled {
                let data = LocalFile.url(filename).flatMap { try? Data(contentsOf: $0) }
                if data != last {
                    last = data
                    if let data,
                       let envelope = try? JSONDecoder().decode(RuntimeStateEnvelope.self, from: data),
                       Date().timeIntervalSinceReferenceDate - envelope.publishedAt < expiresAfter {
                        continuation.yield(envelope.state)
                    }
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
