import SwiftUI
import GrainDomain
import GrainApplication

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ProgressRing(fraction: phaseRemainingFraction, color: phaseColor)
                .frame(width: 300, height: 300)
            VStack(spacing: 8) {
                Text((currentTag ?? .a).label)
                    .font(.customRegular(size: 28))
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(timerRuntime.status == .idle ? 0 : 1)
                Text(format(timerRuntime.remainingTime))
                    .font(.customMonospaced(size: 76))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                CompactControlPanel(status: timerRuntime.status) { showingSettings = true }
                    .foregroundStyle(.white)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 40)
        }
        .animation(.linear(duration: 0.3), value: phaseRemainingFraction)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }

    private var currentTag: IntervalTag? {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return nil }
        return intervals[idx.index].tag
    }

    private var phaseRemainingFraction: Double {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return 1 }
        let total = intervals[idx.index].duration.millis
        guard total > 0 else { return 1 }
        let clamped = min(timerRuntime.remainingTime.millis, total)
        return Double(clamped) / Double(total)
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var phaseColor: Color {
        currentTag?.color ?? Color(white: 0.3)
    }
}

private struct ProgressRing: View {
    let fraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .shadow(color: color.opacity(0.7), radius: 8)
                .shadow(color: color.opacity(0.45), radius: 16)
                .shadow(color: color.opacity(0.25), radius: 24)
                .rotationEffect(.degrees(-90))
        }
    }
}
