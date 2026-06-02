import UserNotifications

@MainActor
final class NotificationService {

    func requestAuthorization() {
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }

    func notifyPhaseCompleted(phaseName: String) {
        send(title: "\(phaseName) completed")
    }

    func notifySessionCompleted() {
        send(title: "Session completed")
    }

    func notifyStateRecovered() {
        send(title: "Session restored", body: "Timer has been fast-forwarded")
    }

    private func send(title: String, body: String? = nil) {
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
