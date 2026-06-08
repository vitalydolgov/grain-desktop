import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(AppSettings.self) private var settings

    var body: some View {
        switch settings.preferences.menuBarLabelFormat {
        case .time:
            Text(format(timerRuntime.remainingTime))
        case .minutes:
            Text(formatMinutes(timerRuntime.remainingTime))
        case .icon:
            Image(systemName: "ring")
        }
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func formatMinutes(_ duration: Duration) -> String {
        let minutes = Int(ceil(Double(duration.seconds) / 60))
        return "\(minutes)m"
    }
}

