import Foundation
import GrainApplication

enum RuntimeStateSync {
    enum Source: String {
        case desktop
    }

    static func publisher(as source: Source) -> any RuntimeStatePublisher {
        var channels: [any RuntimeStatePublisher] = []
        #if DEBUG
        channels.append(LocalRuntimeStatePublisher(source: source))
        #endif
        channels.append(CloudRuntimeStatePublisher(source: source))
        return CompositePublisher(channels)
    }

    static func wearableSubscriber(following source: Source) -> any RuntimeStateSubscriber {
        #if targetEnvironment(simulator)
        LocalRuntimeStateSubscriber(source: source)
        #else
        CloudRuntimeStateSubscriber(source: source)
        #endif
    }
}

private struct CompositePublisher: RuntimeStatePublisher {
    let channels: [any RuntimeStatePublisher]

    init(_ channels: [any RuntimeStatePublisher]) {
        self.channels = channels
    }

    func publish(_ state: RuntimeState) {
        for channel in channels {
            channel.publish(state)
        }
    }
}
