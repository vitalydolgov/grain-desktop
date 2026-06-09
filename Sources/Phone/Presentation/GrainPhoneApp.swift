import SwiftUI
import UIKit
import GrainApplication
import GrainComponents

@main
struct GrainPhoneApp: App {
    @State private var settings = AppSettings(plan: PlanSettings(store: UserDefaultsPlanSettingsStore()))
    @State private var timerRuntime = RuntimeProxy()
    @State private var theme = AppTheme(PhoneThemeFactory())

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .environment(settings)
                .appTheme(theme)
                .task {
                    await settings.load()
                    if let plan = settings.configuration.makePlan() {
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
