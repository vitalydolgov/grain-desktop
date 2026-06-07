import SwiftUI
import GrainDomain

struct FloatingTimerView: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            TimerContent()
                .foregroundStyle(.primary)
        }
        .frame(width: 250)
        .background(FloatingWindowConfigurator(keepOnTop: true))
        .ignoresSafeArea()
    }
}

@available(macOS 26.0, *)
struct GlassFloatingTimerView: View {
    var body: some View {
        TimerContent()
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .background(FloatingWindowConfigurator(
                keepOnTop: true,
                movableByBackground: true,
                transparentBackground: true
            ))
            .containerBackground(.clear, for: .window)
            .ignoresSafeArea()
    }
}

private struct TimerContent: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            IntervalDots(
                count: timerRuntime.plan.intervals.count,
                currentIndex: timerRuntime.currentIndex.index,
                color: phaseColor,
                inactiveColor: inactiveDotColor
            )
            .opacity(timerRuntime.status == .idle ? 0 : 1)
            Text(format(timerRuntime.remainingTime))
                .font(.customMonospaced(size: 60))
                .animation(.snappy, value: timerRuntime.remainingTime)
            CompactControlPanel(status: timerRuntime.status)
        }
    }

    private var phaseColor: Color {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return Color(white: 0.3) }
        return intervals[idx.index].tag.color
    }

    private var inactiveDotColor: Color {
        (colorScheme == .dark ? Color.white : Color.black).opacity(0.25)
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
