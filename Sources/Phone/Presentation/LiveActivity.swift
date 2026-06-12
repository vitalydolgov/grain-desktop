@preconcurrency import ActivityKit
import Foundation
import GrainDomain
import GrainApplication
import GrainComponents

@MainActor
struct LiveActivity {
    private var activity: Activity<TimerActivityAttributes>?

    mutating func update(from state: RuntimeState) async {
        switch state.timer.status {
        case .running:
            let content = contentState(for: state)
            if activity == nil {
                requestActivity(content)
            } else {
                await activity?.update(ActivityContent(state: content, staleDate: nil))
            }
        case .paused:
            await activity?.update(ActivityContent(state: contentState(for: state), staleDate: nil))
        case .idle, .completed:
            if let current = activity {
                activity = nil
                await current.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func contentState(for state: RuntimeState) -> TimerActivityAttributes.ContentState {
        let idx = state.timer.currentIndex
        let tag: IntervalTag? = idx.index < state.plan.intervals.count ? state.plan.intervals[idx.index].tag : nil
        let face = TimerFace(status: state.timer.status, tag: tag)
        let seconds = Int(state.timer.remainingTime.seconds)
        return TimerActivityAttributes.ContentState(
            phaseLabel: face.label,
            isRunning: state.timer.status == .running,
            endDate: Date.now.addingTimeInterval(Double(seconds)),
            remainingSeconds: seconds
        )
    }

    private mutating func requestActivity(_ state: TimerActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity.request(
                attributes: TimerActivityAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {}
    }
}
