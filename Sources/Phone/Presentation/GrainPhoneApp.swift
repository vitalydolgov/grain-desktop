import SwiftUI
import UIKit
import GrainApplication

@main
struct GrainPhoneApp: App {
    @State private var timerRuntime = RuntimeProxy()

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
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
                    let relay = RuntimeStateRelay(publisher: RuntimeStateSync.publisher(as: .phone))
                    await relay.transmit(states: await timerRuntime.runtimeStates())
                }
        }
    }
}
