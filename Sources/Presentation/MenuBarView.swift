import SwiftUI
import GrainApplication

struct MenuBarView: View {
    @Environment(TimerService.self) private var timerService

    var body: some View {
        Text(format(timerService.remainingTime))
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.millis / 1000
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
