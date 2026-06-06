import SwiftUI
import GrainDomain

struct FloatingTimerView: View {
    var body: some View {
        ZStack {
            Color.black
            TimerContent()
                .foregroundStyle(.white)
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
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 12) {
            IntervalDots(
                currentIndex: timerRuntime.currentIndex.index,
                total: timerRuntime.plan.intervals.count,
                color: phaseColor
            )
            .opacity(timerRuntime.status == .idle ? 0 : 1)
            Text(format(timerRuntime.remainingTime))
                .font(.customMonospaced(size: 60))
                .animation(.snappy, value: timerRuntime.remainingTime)
            CompactControlPanel(status: timerRuntime.status) { openSettings() }
        }
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
                    .fill(i <= currentIndex ? color : Color.white.opacity(0.25))
                    .frame(
                        width: i == currentIndex ? 8 : 6,
                        height: i == currentIndex ? 8 : 6
                    )
                    .shadow(
                        color: i == currentIndex ? color.opacity(0.8) : .clear,
                        radius: 4
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}
