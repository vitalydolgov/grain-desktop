import SwiftUI
import GrainDomain
import GrainApplication

struct MenuBarView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.menuBarLabelFormat) private var labelFormat

    var body: some View {
        switch labelFormat {
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

private struct MenuBarLabelFormatKey: EnvironmentKey {
    static let defaultValue: MenuBarLabelFormat = .time
}

extension EnvironmentValues {
    var menuBarLabelFormat: MenuBarLabelFormat {
        get { self[MenuBarLabelFormatKey.self] }
        set { self[MenuBarLabelFormatKey.self] = newValue }
    }
}
