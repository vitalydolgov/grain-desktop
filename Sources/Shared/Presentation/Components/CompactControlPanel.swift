import SwiftUI
import GrainDomain

struct CompactControlPanel: View {
    let status: SessionStatus
    let onSettings: () -> Void
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                Image(systemName: playbackIcon)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 24)
            }
            if isStopped {
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            } else {
                Button { timerRuntime.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var isStopped: Bool {
        status == .idle || status == .completed
    }

    private func togglePlayback() {
        switch status {
        case .running: timerRuntime.pause()
        case .paused: timerRuntime.resume()
        case .idle, .completed: timerRuntime.start()
        }
    }

    private var playbackIcon: String {
        status == .running ? "pause.fill" : "play.fill"
    }
}
