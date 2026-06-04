import UserNotifications

@MainActor
enum NotificationService {
    private static let delegate = ForegroundPresenter()

    static func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = delegate
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }

    static func notifyPhaseCompleted(phaseName: String) {
        send(title: "\(phaseName) completed")
    }

    static func notifySessionCompleted(whileAway: Bool = false) {
        send(title: "Session completed", body: whileAway ? "Timer ran out while away" : nil)
    }

    static func notifyStateRecovered() {
        send(title: "Session restored", body: "Timer has been fast-forwarded")
    }

    private static func send(title: String, body: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body { content.body = body }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
