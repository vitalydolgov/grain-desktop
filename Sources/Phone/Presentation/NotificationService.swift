import UserNotifications
import AudioToolbox
import GrainDomain
import GrainComponents

@MainActor
enum NotificationService {
    private static let delegate = ForegroundPresenter()
    private static let beepSound: SystemSoundID = {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav") else {
            preconditionFailure("beep.wav missing from bundle")
        }
        var id: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &id)
        return id
    }()

    static func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = delegate
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
    }

    static func notifyPhaseCompleted(tag: IntervalTag) {
        AudioServicesPlayAlertSound(beepSound)
    }

    static func notifySessionCompleted(whileAway: Bool = false) {
        if whileAway {
            send(title: "Session completed", body: "Timer ran out while away")
        } else {
            AudioServicesPlayAlertSound(beepSound)
        }
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
