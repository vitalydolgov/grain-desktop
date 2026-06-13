import UserNotifications
import GrainApplication

@MainActor
protocol NotificationHandling {
    static func requestAuthorization() async throws
    static func realize(intents: AsyncStream<NotificationIntent>) async
}

private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@MainActor private let sharedDelegate = ForegroundPresenter()

extension NotificationHandling {
    static func requestAuthorization() async throws {
        UNUserNotificationCenter.current().delegate = sharedDelegate
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }
}
