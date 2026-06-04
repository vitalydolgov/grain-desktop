import SwiftUI
import GrainApplication

@main
struct GrainWatchApp: App {
    @State private var timerRuntime = RuntimeProxy()
    @State private var stateSubscriber = RuntimeStateSync.wearableSubscriber(following: .desktop)

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .task {
                    for await state in stateSubscriber.states {
                        timerRuntime.restore(from: state)
                    }
                }
        }
    }
}
