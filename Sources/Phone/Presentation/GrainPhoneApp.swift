import SwiftUI
import UIKit
import GrainApplication

@main
struct GrainPhoneApp: App {
    @State private var timerRuntime: RuntimeProxy
    @State private var synchronizer: RuntimeSynchronizer

    init() {
        let timerRuntime = RuntimeProxy(runtime: TimerRuntime())
        let synchronizer = RuntimeSynchronizer(delegate: timerRuntime)
        _timerRuntime = State(wrappedValue: timerRuntime)
        _synchronizer = State(wrappedValue: synchronizer)
    }

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .environment(synchronizer)
                .preferredColorScheme(.dark)
                .task {
                    for await signal in timerRuntime.signals() {
                        switch signal {
                        case .intervalCompleted:
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        case .sessionCompleted, .sessionCompletedWhileAway:
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        case .sessionRestored:
                            break
                        }
                    }
                }
                .task {
                    for await status in timerRuntime.statuses {
                        synchronizer.status = status
                    }
                }
        }
    }
}
