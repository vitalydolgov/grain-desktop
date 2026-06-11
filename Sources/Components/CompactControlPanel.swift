import SwiftUI
import GrainDomain
import GrainApplication

public struct CompactControlPanel: View {
    let status: SessionStatus
    let onCommand: (RuntimeCommand) -> Void
    let onSettings: (() -> Void)?

    public init(status: SessionStatus,
                onCommand: @escaping (RuntimeCommand) -> Void,
                onSettings: (() -> Void)? = nil) {
        self.status = status
        self.onCommand = onCommand
        self.onSettings = onSettings
    }

    public var body: some View {
        HStack(spacing: 16) {
            Button {
                switch status {
                case .running: onCommand(.pause)
                case .paused: onCommand(.resume)
                case .idle, .completed: onCommand(.start)
                }
            } label: {
                ControlPanelIcon(systemName: status == .running ? "pause.fill" : "play.fill")
            }
            if status == .running {
                Button { onCommand(.skip) } label: {
                    ControlPanelIcon(systemName: "forward.end.fill")
                }
            } else if status == .idle || status == .completed, let onSettings {
                Button(action: onSettings) {
                    ControlPanelIcon(systemName: "gearshape.fill")
                }
            } else {
                Button { onCommand(.reset) } label: {
                    ControlPanelIcon(systemName: "arrow.counterclockwise")
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ControlPanelIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .bold))
            .frame(width: 24, height: 24)
    }
}
