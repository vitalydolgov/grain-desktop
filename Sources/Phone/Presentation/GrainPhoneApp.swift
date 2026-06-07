import SwiftUI
import UIKit
import GrainApplication

@main
struct GrainPhoneApp: App {
    @State private var settings = AppSettings(plan: PlanSettings(store: UserDefaultsPlanSettingsStore()))
    @State private var timerRuntime = RuntimeProxy()

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .environment(settings)
                .task {
                    if let plan = (await settings.plan.load()).makePlan() {
                        timerRuntime.setPlan(plan)
                    }
                }
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
        }
    }
}
