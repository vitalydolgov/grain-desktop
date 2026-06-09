import SwiftUI
import GrainDomain
import GrainApplication

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(RuntimeSynchronizer.self) private var synchronizer
    @State private var showingRemoteSyncPrompt = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ProgressRing(fraction: phaseRemainingFraction, color: phaseColor, isLit: timerRuntime.status != .idle)
                .padding(-6)
            VStack(spacing: 2) {
                Text((currentTag ?? .a).label)
                    .font(.customRegular(size: 20))
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(timerRuntime.status == .idle ? 0 : 1)
                Text(format(timerRuntime.remainingTime))
                    .font(.customMonospaced(size: 40))
                    .foregroundStyle(.white)
                Group {
                    if case .synced = synchronizer.syncMode {
                        Image(systemName: "personalhotspot")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        CompactControlPanel(status: timerRuntime.status) { showingSettings = true }
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
        }
        .animation(.linear(duration: 0.3), value: phaseRemainingFraction)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .alert("Sync with Mac?", isPresented: $showingRemoteSyncPrompt) {
            Button("Sync") { synchronizer.acceptSync() }
            Button("Not Now", role: .cancel) { synchronizer.declineSync() }
        } message: {
            Text("A session is running on your Mac.")
        }
        .onChange(of: synchronizer.syncMode.isPending) { _, isPending in
            showingRemoteSyncPrompt = isPending
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
        return String(format: "%llu:%02llu", total / 60, total % 60)
    }

    private var phaseColor: Color {
        currentTag?.color ?? Color(white: 0.3)
    }
}

private extension SyncMode {
    var isPending: Bool { if case .pending = self { true } else { false } }
}

private struct ProgressRing: View {
    // Equal length: the keyframe builder forbids control flow, so the track emits a fixed eight keyframes.
    private static let fourBlinkValues: [Double] = [0.0, 0.9, 0.0, 0.55, 0.05, 1.0, 0.3, 1.0]
    private static let threeBlinkValues: [Double] = [0.0, 0.9, 0.0, 0.55, 0.05, 0.5, 0.75, 1.0]
    private static let baseDurations: [Double] = [0.08, 0.05, 0.065, 0.05, 0.09, 0.05, 0.065, 0.235]

    let fraction: Double
    let color: Color
    let isLit: Bool
    @State private var ignition = 0
    @State private var values = ProgressRing.fourBlinkValues
    @State private var durations = ProgressRing.baseDurations

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .keyframeAnimator(initialValue: 0.0, trigger: ignition) { content, glow in
                    let g = isLit ? glow : 0
                    content
                        .opacity(g)
                        .shadow(color: color.opacity(0.7 * g), radius: 6)
                        .shadow(color: color.opacity(0.45 * g), radius: 13)
                        .shadow(color: color.opacity(0.25 * g), radius: 20)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        LinearKeyframe(values[0], duration: durations[0])
                        LinearKeyframe(values[1], duration: durations[1])
                        LinearKeyframe(values[2], duration: durations[2])
                        LinearKeyframe(values[3], duration: durations[3])
                        LinearKeyframe(values[4], duration: durations[4])
                        LinearKeyframe(values[5], duration: durations[5])
                        LinearKeyframe(values[6], duration: durations[6])
                        CubicKeyframe(values[7], duration: durations[7])
                    }
                }
        }
        .onChange(of: isLit) { _, lit in
            if lit {
                values = Bool.random() ? Self.fourBlinkValues : Self.threeBlinkValues
                durations = Self.baseDurations.map { $0 * Double.random(in: 0.5...1.5) }
                ignition += 1
            }
        }
    }
}
