import UserNotifications
import AudioToolbox
import GrainApplication

@MainActor
enum PhoneNotification: NotificationHandling {
    static func realize(intent: NotificationIntent) {
        switch intent {
        case .intervalCompleted, .sessionCompleted:
            beep()
        case .sessionCompletedWhileAway:
            break
        case .sessionRestored:
            send(title: "Session restored", body: "Timer has been fast-forwarded")
        }
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

    private static func beep() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav")
        else { preconditionFailure("beep.wav missing from bundle") }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlayAlertSound(soundID)
    }
}
