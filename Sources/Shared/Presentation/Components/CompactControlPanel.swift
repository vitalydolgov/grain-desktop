import SwiftUI
import GrainDomain

struct CompactControlPanel: View {
    let status: SessionStatus
    let onSettings: (() -> Void)?
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                ControlPanelIcon(systemName: status == .running ? "pause.fill" : "play.fill")
            }
            if status == .running {
                Button { timerRuntime.skip() } label: {
                    ControlPanelIcon(systemName: "forward.end.fill")
                }
            } else if status == .idle || status == .completed, let onSettings {
                Button(action: onSettings) {
                    ControlPanelIcon(systemName: "gearshape.fill")
                }
            } else {
                Button { timerRuntime.reset() } label: {
                    ControlPanelIcon(systemName: "arrow.counterclockwise")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var isInactive: Bool {
        status == .idle || status == .completed
    }

    private func togglePlayback() {
        switch status {
        case .running: timerRuntime.pause()
        case .paused: timerRuntime.resume()
        case .idle, .completed: timerRuntime.start()
        }
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
