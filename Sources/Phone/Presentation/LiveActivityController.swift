import ActivityKit
import Foundation
import GrainDomain

/// Bridges the timer's session state to a lock-screen Live Activity.
@MainActor
final class LiveActivityController {
    private var activity: Activity<GrainActivityAttributes>?

    func sync(status: SessionStatus, phaseLabel: String, remainingTime: Duration) {
        switch status {
        case .running, .paused:
            let remainingSeconds = remainingTime.seconds
            let phaseEnd = Date.now.addingTimeInterval(Double(remainingTime.millis) / 1000)
            let state = GrainActivityAttributes.ContentState(
                phaseLabel: phaseLabel,
                isRunning: status == .running,
                phaseEnd: phaseEnd,
                remainingSeconds: remainingSeconds
            )
            push(state)
        case .idle, .completed:
            end()
        }
    }

    private func push(_ state: GrainActivityAttributes.ContentState) {
        let content = ActivityContent(state: state, staleDate: nil)
        if let activity {
            Task { await activity.update(content) }
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            activity = try? Activity.request(
                attributes: GrainActivityAttributes(),
                content: content
            )
        }
    }

    private func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
