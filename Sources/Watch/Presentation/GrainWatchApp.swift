import SwiftUI
import WatchKit
import GrainApplication

@main
struct GrainWatchApp: App {
    @State private var timerRuntime = RuntimeProxy()

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .task {
                    for await signal in timerRuntime.signals() {
                        play(for: signal)
                    }
                }
        }
    }

    private func play(for signal: TimerSignal) {
        switch signal {
        case .phaseCompleted:
            WKInterfaceDevice.current().play(.notification)
        case .sessionCompleted, .sessionCompletedWhileAway:
            WKInterfaceDevice.current().play(.success)
        case .sessionRestored:
            break
        }
    }
}
