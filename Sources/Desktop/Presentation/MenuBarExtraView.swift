import SwiftUI
import GrainDomain

struct MenuBarExtraView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimerActions(runStatus: timerRuntime.status)
            Divider()
            MenuRow("Floating Window") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "floating-timer")
            }
            Divider()
            MenuRow("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            Divider()
            MenuRow("Quit") { NSApp.terminate(nil) }
        }
        .frame(width: 200)
    }

    private var currentIntervalTag: IntervalTag? {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard timerRuntime.status != .idle, idx.index < intervals.count else { return nil }
        return intervals[idx.index].tag
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct TimerActions: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    let runStatus: SessionStatus

    var body: some View {
        switch runStatus {
        case .running:
            MenuRow("Pause") { timerRuntime.pause() }
        case .paused:
            MenuRow("Resume") { timerRuntime.resume() }
        case .idle, .completed:
            MenuRow("Start") { timerRuntime.start() }
        }
        MenuRow("Reset") { timerRuntime.reset() }
            .disabled(runStatus == .idle)
    }
}

private struct MenuRow: View {
    let label: String
    let action: () -> Void

    init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}
