import UserNotifications
import GrainDomain
import GrainApplication

@MainActor
enum DesktopNotification: NotificationHandling {
    static func realize(intents: AsyncStream<NotificationIntent>) async {
        for await intent in intents {
            switch intent {
            case .intervalCompleted(let tag):
                send(title: "\(tag == .a ? "Focus" : "Break") completed", sound: beep)
            case .sessionCompleted:
                send(title: "Session completed", sound: beep)
            case .sessionCompletedWhileAway:
                send(title: "Session completed", body: "Timer ran out while away")
            case .sessionRestored:
                send(title: "Session restored", body: "Timer has been fast-forwarded")
            }
        }
    }

    private static var beep: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName(rawValue: "beep.wav"))
    }

    private static func send(title: String, body: String? = nil, sound: UNNotificationSound? = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body { content.body = body }
        content.sound = sound
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
