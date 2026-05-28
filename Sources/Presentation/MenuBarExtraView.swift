import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarExtraView: View {
    @Environment(TimerService.self) private var timerService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimerHeader(
                displayTime: format(timerService.remainingTime),
                currentRound: timerService.currentLocation?.round ?? 1,
                phaseKind: timerService.currentLocation?.kind ?? .a,
                partAName: timerService.settings.partAName,
                partBName: timerService.settings.partBName
            )
            Divider()
            TimerActions(runState: timerService.runState)
            Divider()
            TimerSettingsRow()
        }
        .frame(width: 200)
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.millis / 1000
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct TimerHeader: View {
    let displayTime: String
    let currentRound: Int
    let phaseKind: PhaseKind?
    let partAName: String
    let partBName: String

    var body: some View {
        HStack {
            Text(displayTime)
                .font(.system(.title, design: .monospaced))
                .monospacedDigit()
            Text("R\(currentRound)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let kind = phaseKind {
                Text(kind == .a ? partAName : partBName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct TimerActions: View {
    @Environment(TimerService.self) private var timerService
    let runState: RunState

    var body: some View {
        switch runState {
        case .running:
            MenuRow("Pause") { Task { try? await timerService.pause() } }
        case .paused:
            MenuRow("Resume") { Task { try? await timerService.resume() } }
        case .idle, .completed:
            MenuRow("Start") { Task { try? await timerService.start() } }
        }
        MenuRow("Reset") { Task { try? await timerService.reset() } }
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
