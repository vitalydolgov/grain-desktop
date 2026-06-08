import SwiftUI
import GrainDomain

struct CompactControlPanel: View {
    let status: SessionStatus
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                Image(systemName: status == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            if status == .running {
                Button { timerRuntime.skip() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 24, height: 24)
                }
            } else {
                Button { timerRuntime.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 24, height: 24)
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
}
