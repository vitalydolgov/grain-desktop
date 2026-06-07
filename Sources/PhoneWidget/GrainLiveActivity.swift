import ActivityKit
import SwiftUI
import WidgetKit

/// Lock-screen Live Activity for the Grain timer.
struct GrainLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GrainActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    TimeText(state: context.state)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                TimeText(state: context.state)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private struct LockScreenView: View {
    let state: GrainActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.phaseLabel)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                TimeText(state: state)
                    .font(.system(size: 44, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
    }
}

/// Live-counting time while running, frozen formatted time while paused.
private struct TimeText: View {
    let state: GrainActivityAttributes.ContentState

    var body: some View {
        if state.isRunning {
            Text(timerInterval: Date.now...state.phaseEnd, countsDown: true)
        } else {
            Text(formatted(state.remainingSeconds))
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
