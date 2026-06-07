import SwiftUI
import GrainDomain
import GrainApplication

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(RuntimeSynchronizer.self) private var synchronizer
    @State private var showingSettings = false
    @State private var showingRemoteSyncPrompt = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ProgressRing(fraction: phaseRemainingFraction, color: phaseColor)
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
        .alert(syncPromptTitle, isPresented: $showingRemoteSyncPrompt) {
            Button("Sync") { synchronizer.acceptSync() }
            Button("Not Now", role: .cancel) { synchronizer.declineSync() }
        } message: {
            Text(syncPromptMessage)
        }
        .onChange(of: synchronizer.syncMode.isPending) { _, isPending in
            showingRemoteSyncPrompt = isPending
        }
    }

    private var syncSourceName: String {
        switch synchronizer.pendingSource {
        case .desktop?: "Mac"
        case .phone?: "iPhone"
        case nil: "device"
        }
    }

    private var syncPromptTitle: String {
        "Sync with \(syncSourceName)?"
    }

    private var syncPromptMessage: String {
        "A session is running on your \(syncSourceName)."
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

private extension SyncMode {
    var isPending: Bool { if case .pending = self { true } else { false } }
}

private struct ProgressRing: View {
    let fraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .shadow(color: color.opacity(0.7), radius: 6)
                .shadow(color: color.opacity(0.45), radius: 13)
                .shadow(color: color.opacity(0.25), radius: 20)
                .rotationEffect(.degrees(-90))
        }
    }
}
