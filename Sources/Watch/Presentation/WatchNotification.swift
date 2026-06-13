import WatchKit
import GrainApplication

@MainActor
enum WatchNotification: NotificationHandling {
    static func requestAuthorization() {}

    static func realize(intents: AsyncStream<NotificationIntent>) async {
        for await intent in intents {
            switch intent {
            case .intervalCompleted:
                WKInterfaceDevice.current().play(.notification)
            case .sessionCompleted, .sessionCompletedWhileAway:
                WKInterfaceDevice.current().play(.success)
            case .sessionRestored:
                break
            }
        }
    }
}
