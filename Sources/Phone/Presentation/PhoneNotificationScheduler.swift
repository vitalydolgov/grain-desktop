import UserNotifications
import GrainDomain
import GrainApplication

@MainActor
enum PhoneNotificationScheduler {
    static func schedule(plan: SessionPlan, from index: IntervalIndex, remaining: Duration) {
        cancelAll()
        let intervals = plan.intervals
        guard index.index < intervals.count else { return }

        var offset = Double(remaining.millis) / 1000
        for position in index.index..<intervals.count {
            if position > index.index {
                offset += Double(intervals[position].duration.millis) / 1000
            }
            guard offset > 0 else { continue }
            let message = message(for: position, in: intervals)
            notify(message: message, after: offset, identifier: "grain.phase.\(position)")
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func message(for position: Int, in intervals: [Interval]) -> (String, String) {
        let next = position + 1
        guard next < intervals.count else {
            return ("Session completed", "Nice work")
        }
        return (
            "\(intervals[position].tag == .a ? "Focus" : "Break") completed",
            "\(intervals[next].tag == .a ? "Focus" : "Break") starts now"
        )
    }

    private static func notify(message: (String, String), after delay: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = message.0
        content.body = message.1
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "beep.wav"))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
