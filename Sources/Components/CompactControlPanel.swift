import SwiftUI
import GrainDomain

@MainActor
public protocol RuntimeControlProtocol: AnyObject {
    func start()
    func pause()
    func resume()
    func skip()
    func reset()
}

public struct CompactControlPanel: View {
    let status: SessionStatus
    let control: any RuntimeControlProtocol
    let onSettings: (() -> Void)?

    public init(status: SessionStatus,
                control: any RuntimeControlProtocol,
                onSettings: (() -> Void)? = nil) {
        self.status = status
        self.control = control
        self.onSettings = onSettings
    }

    public var body: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                ControlPanelIcon(systemName: status == .running ? "pause.fill" : "play.fill")
            }
            if status == .running {
                Button(action: control.skip) {
                    ControlPanelIcon(systemName: "forward.end.fill")
                }
            } else if status == .idle || status == .completed, let onSettings {
                Button(action: onSettings) {
                    ControlPanelIcon(systemName: "gearshape.fill")
                }
            } else {
                Button(action: control.reset) {
                    ControlPanelIcon(systemName: "arrow.counterclockwise")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func togglePlayback() {
        switch status {
        case .running: control.pause()
        case .paused: control.resume()
        case .idle, .completed: control.start()
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
