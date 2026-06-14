import WatchKit
import GrainApplication

@MainActor
enum WatchNotification: NotificationHandling {
    static func requestAuthorization() {}

    static func realize(intent: NotificationIntent) {
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
