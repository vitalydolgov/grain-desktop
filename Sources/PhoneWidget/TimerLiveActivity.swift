import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding(20)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phaseLabel.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    TimerText(state: context.state)
                        .font(.system(size: 40, weight: .semibold, design: .monospaced))
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                TimerText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private struct LockScreenView: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            Text(state.phaseLabel.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(4)
                .foregroundStyle(.secondary)
            TimerText(state: state)
                .font(.system(size: 56, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TimerText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.isRunning {
            Text(timerInterval: Date.now...state.endDate, countsDown: true)
                .multilineTextAlignment(.center)
        } else {
            Text(formatted(state.remainingSeconds))
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
