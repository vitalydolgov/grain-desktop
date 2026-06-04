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
        #if targetEnvironment(simulator)
        guard let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return nil }
        home = URL(fileURLWithPath: hostHome)
        #else
        home = FileManager.default.homeDirectoryForCurrentUser
        #endif
        return home.appendingPathComponent("Library/Caches/Grain/\(filename)")
    }
}

struct LocalRuntimeStatePublisher: RuntimeStatePublisher {
    let source: RuntimeStateSync.Source

    func publish(_ state: RuntimeState) {
        guard let url = LocalFile.url(source.localFilename), let data = try? JSONEncoder().encode(state) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}

struct LocalRuntimeStateSubscriber: RuntimeStateSubscriber {
    let states: AsyncStream<RuntimeState>

    init(source: RuntimeStateSync.Source) {
        let (states, continuation) = AsyncStream.makeStream(of: RuntimeState.self)
        self.states = states
        let filename = source.localFilename
        Task {
            var last: Data?
            while !Task.isCancelled {
                let data = LocalFile.url(filename).flatMap { try? Data(contentsOf: $0) }
                if data != last {
                    last = data
                    if let data, let state = try? JSONDecoder().decode(RuntimeState.self, from: data) {
                        continuation.yield(state)
                    }
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
