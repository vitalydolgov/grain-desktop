import SwiftUI
import GrainDomain
import GrainApplication
import GrainComponents

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(RuntimeSynchronizer.self) private var synchronizer
    @State private var showingRemoteSyncPrompt = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ProgressRing()
                .padding(-6)
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    if case .synced = synchronizer.syncMode {
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(phaseColor)
                    }
                    Text((currentTag ?? .a).label)
                        .font(.customRegular(size: 20))
                        .foregroundStyle(phaseColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .opacity(timerRuntime.status == .idle || timerRuntime.status == .completed ? 0 : 1)
                Text(format(timerRuntime.remainingTime))
                    .font(.customMonospaced(size: 40))
                    .foregroundStyle(.white)
                CompactControlPanel(status: timerRuntime.status,
                                    onCommand: handler.handle,
                                    onSettings: { showingSettings = true })
                .foregroundStyle(.white)
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .alert("Sync with iPhone?", isPresented: $showingRemoteSyncPrompt) {
            Button("Sync") { synchronizer.acceptSync() }
            Button("Not Now", role: .cancel) { synchronizer.declineSync() }
        } message: {
            Text("A session is currently running.")
        }
        .onChange(of: isSyncPending) { _, isSyncPending in
            showingRemoteSyncPrompt = isSyncPending
        }
    }

    private var isSyncPending: Bool {
        if case .pending = synchronizer.syncMode {
            true
        } else {
            false
        }
    }

    private var currentTag: IntervalTag? {
        guard timerRuntime.status != .idle, timerRuntime.status != .completed else { return nil }
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return nil }
        return intervals[idx.index].tag
    }

    private var handler: any RuntimeCommandHandler {
        if case .synced = synchronizer.syncMode {
            synchronizer
        } else {
            timerRuntime
        }
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%llu:%02llu", total / 60, total % 60)
    }

    private var phaseColor: Color {
        switch currentTag {
        case .a: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .b: Color(red: 0.96, green: 0.72, blue: 0.16)
        case nil: Color(white: 0.3)
        }
    }
}

private struct ProgressRing: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        let color = color

        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: isLit ? color.opacity(0.7) : .clear, radius: 6)
                .shadow(color: isLit ? color.opacity(0.45) : .clear, radius: 13)
                .shadow(color: isLit ? color.opacity(0.25) : .clear, radius: 20)
        }
        .animation(.linear(duration: 0.3), value: fraction)
    }

    private var currentTag: IntervalTag? {
        guard timerRuntime.status != .idle, timerRuntime.status != .completed else { return nil }
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return nil }
        return intervals[idx.index].tag
    }

    private var fraction: Double {
        guard isLit else { return 1 }
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return 1 }
        let total = intervals[idx.index].duration.millis
        guard total > 0 else { return 1 }
        let clamped = min(timerRuntime.remainingTime.millis, total)
        return Double(clamped) / Double(total)
    }

    private var color: Color {
        switch currentTag {
        case .a: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .b: Color(red: 0.96, green: 0.72, blue: 0.16)
        case nil: Color(white: 0.3)
        }
    }

    private var isLit: Bool {
        timerRuntime.status == .running || timerRuntime.status == .paused
    }
}
