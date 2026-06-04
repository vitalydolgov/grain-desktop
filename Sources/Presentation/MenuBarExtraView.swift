import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarExtraView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimerHeader(
                displayTime: format(timerRuntime.remainingTime),
                currentCycle: timerRuntime.currentLocation?.cycle ?? 1,
                phaseKind: timerRuntime.currentLocation?.kind ?? .phaseA,
                phaseAName: settings.preferences.phaseLabels.phaseA,
                phaseBName: settings.preferences.phaseLabels.phaseB
            )
            Divider()
            TimerActions(runState: timerRuntime.state)
            Divider()
            TimerSettingsRow()
            Divider()
            MenuRow("Quit") { NSApp.terminate(nil) }
        }
        .frame(width: 200)
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct TimerHeader: View {
    let displayTime: String
    let currentCycle: Int
    let phaseKind: PhaseKind?
    let phaseAName: String
    let phaseBName: String

    var body: some View {
        HStack {
            Text(displayTime)
                .font(.system(.title, design: .monospaced))
                .monospacedDigit()
            Text("#\(currentCycle)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            if let kind = phaseKind {
                HStack(spacing: 4) {
                    Image(systemName: kind == .phaseA ? "a.circle" : "b.circle")
                    Text(kind == .phaseA ? phaseAName : phaseBName)
                }
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
    let runState: SessionState

    var body: some View {
        switch runState {
        case .running:
            MenuRow("Pause") { timerRuntime.pause() }
        case .paused:
            MenuRow("Resume") { timerRuntime.resume() }
        case .idle, .completed:
            MenuRow("Start") { timerRuntime.start() }
        }
        MenuRow("Reset") { timerRuntime.reset() }
            .disabled(runState == .idle)
    }
}

private struct TimerSettingsRow: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
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
