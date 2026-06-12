import UserNotifications
import GrainDomain
import GrainApplication

@MainActor
enum PhoneNotificationScheduler {
    static func schedule(plan: SessionPlan, from index: IntervalIndex, remaining: Duration) {
        cancel()
        let intervals = plan.intervals
        guard index.index < intervals.count else { return }

        var offset = Double(remaining.millis) / 1000
        for position in index.index..<intervals.count {
            if position > index.index {
                offset += Double(intervals[position].duration.millis) / 1000
            }
            guard offset > 0 else { continue }
            notify(after: offset, identifier: "grain.phase.\(position)")
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func notify(after delay: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "beep.wav"))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
