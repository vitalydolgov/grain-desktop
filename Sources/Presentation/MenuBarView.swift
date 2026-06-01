import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        Text(format(timerRuntime.remainingTime))
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.millis / 1000
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
