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
                    NotificationService.requestAuthorization()
                }
                .task {
                    let relay = RuntimeStateRelay(publisher: RuntimeConnectivity.statePublisher)
                    await relay.wire(states: await timerRuntime.runtimeStates())
                }
                .task {
                    for await command in RuntimeConnectivity.commands {
                        timerRuntime.handle(command)
                    }
                }
                .task {
                    for await signal in timerRuntime.signals() {
                        switch signal {
                        case .intervalCompleted(let idx):
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            let plan = timerRuntime.plan
                            guard idx.index < plan.intervals.count else { break }
                            NotificationService.notifyPhaseCompleted(tag: plan.intervals[idx.index].tag)
                        case .sessionCompleted:
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            NotificationService.notifySessionCompleted()
                        case .sessionCompletedWhileAway:
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            NotificationService.notifySessionCompleted(whileAway: true)
                        case .sessionRestored:
                            NotificationService.notifyStateRecovered()
                        }
                    }
                }
        }
    }
}
