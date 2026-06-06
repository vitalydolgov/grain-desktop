import SwiftUI
import GrainDomain

struct MenuBarExtraView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimerHeader(displayTime: format(timerRuntime.remainingTime), tag: currentIntervalTag)
            Divider()
            TimerActions(runStatus: timerRuntime.status)
            Divider()
            TimerSettingsRow()
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

private struct TimerHeader: View {
    let displayTime: String
    let tag: IntervalTag?

    var body: some View {
        HStack {
            Text(displayTime)
                .font(.system(.title, design: .monospaced))
                .monospacedDigit()
            Spacer()
            if let tag {
                Text(tag.label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

private struct TimerSettingsRow: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuRow("Keep on Top") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "floating-timer")
        }
        MenuRow("Settings") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
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
