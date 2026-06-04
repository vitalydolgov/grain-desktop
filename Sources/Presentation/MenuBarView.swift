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
        case .icon:
            Image(systemName: phaseImageName)
        }
    }

    private var phaseImageName: String {
        switch timerRuntime.state {
        case .running:
            timerRuntime.currentLocation?.kind == .phaseB ? "b.circle" : "a.circle"
        case .idle, .paused:
            "pause.circle"
        case .completed:
            "checkmark.circle"
        }
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

