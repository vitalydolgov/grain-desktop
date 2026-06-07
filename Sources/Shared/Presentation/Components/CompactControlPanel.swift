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
            switch status {
            case .running:
                Button { timerRuntime.skip() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                Button { timerRuntime.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                }
            case .paused:
                Button { timerRuntime.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                }
            case .idle, .completed:
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .buttonStyle(.plain)
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
