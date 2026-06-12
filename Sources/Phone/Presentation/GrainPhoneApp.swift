import SwiftUI
import UIKit
import GrainApplication
import GrainComponents

@main
struct GrainPhoneApp: App {
    @State private var settings = AppSettings(
        plan: PlanSettings(store: UserDefaultsPlanSettingsStore()),
        runtimeState: RuntimeStateSettings(store: UserDefaultsRuntimeStateStore())
    )
    @State private var timerRuntime = RuntimeProxy()
    @State private var theme = AppTheme(PhoneThemeFactory())

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerRuntime)
                .environment(settings)
                .appTheme(theme)
                .onChange(of: timerRuntime.status) { _, _ in
                    saveRuntimeState()
                }
                .onChange(of: timerRuntime.currentIndex.index) { _, _ in
                    saveRuntimeState()
                }
                .task {
                    await settings.load()
                    if let plan = settings.configuration.makePlan() {
                        timerRuntime.setPlan(plan)
                    }
                    NotificationService.requestAuthorization()
                    if let saved = await settings.runtimeState.load() {
                        await settings.runtimeState.clear()
                        timerRuntime.restore(from: saved)
                    }
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

    private func saveRuntimeState() {
        guard let timer = timerRuntime.timer else { return }
        let state = RuntimeState(snapshot: timer, plan: timerRuntime.plan)
        Task {
            switch timer.status {
            case .running, .paused:
                try? await settings.runtimeState.save(state)
            case .idle, .completed:
                await settings.runtimeState.clear()
            }
        }
    }
}
