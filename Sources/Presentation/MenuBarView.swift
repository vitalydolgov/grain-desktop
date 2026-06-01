import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        HStack(spacing: 8) {
            Text(format(timerRuntime.remainingTime))
        }
    }

    private var phaseImageName: String {
        timerRuntime.currentLocation?.kind == .phaseB ? "b.circle" : "a.circle"
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
