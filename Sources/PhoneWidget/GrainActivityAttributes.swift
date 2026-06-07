import ActivityKit
import Foundation

/// Shared Live Activity contract for the Grain timer, used by app and widget.
struct GrainActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phaseLabel: String
        var isRunning: Bool
        var phaseEnd: Date
        var remainingSeconds: Int
    }
}
