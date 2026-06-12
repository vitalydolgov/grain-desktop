import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phaseLabel: String
        var isRunning: Bool
        var endDate: Date
        var remainingSeconds: Int
    }
}
