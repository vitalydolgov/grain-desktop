import SwiftUI
import GrainDomain

struct FloatingTimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 10) {
                IntervalDots(
                    currentIndex: timerRuntime.currentIndex.index,
                    total: timerRuntime.plan.intervals.count,
                    color: phaseColor
                )
                .opacity(timerRuntime.status == .idle ? 0 : 1)
                Text(format(timerRuntime.remainingTime))
                    .font(.customMonospaced(size: 60))
                    .foregroundStyle(.white)
                CompactControlPanel(status: timerRuntime.status) { openSettings() }
            }
        }
        .frame(width: 250)
        .background(KeepOnTopConfigurator())
        .ignoresSafeArea()
    }

    private var phaseColor: Color {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return Color(white: 0.3) }
        return intervals[idx.index].tag.color
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct IntervalDots: View {
    let currentIndex: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= currentIndex ? color : Color(white: 0.3))
                    .frame(
                        width: i == currentIndex ? 8 : 6,
                        height: i == currentIndex ? 8 : 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}
