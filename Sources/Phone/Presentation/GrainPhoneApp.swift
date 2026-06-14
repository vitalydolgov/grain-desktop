import SwiftUI
import GrainDomain
import GrainApplication
import GrainComponents

@main
struct GrainPhoneApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
                    syncNotifications()
                }
                .onChange(of: timerRuntime.currentIndex.index) { _, _ in
                    saveRuntimeState()
                    syncNotifications()
                }
                .onChange(of: scenePhase) { _, _ in
                    syncNotifications()
                }
                .task {
                    await settings.load()
                    if let plan = settings.configuration.makePlan() {
                        timerRuntime.setPlan(plan)
                    }
                    try? await PhoneNotification.requestAuthorization()
                    PhoneNotificationScheduler.cancelAll()
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
                    for await intent in timerRuntime.intents() {
                        PhoneNotification.realize(intent: intent)
                    }
                }
        }
    }

    private func syncNotifications() {
        if timerRuntime.status == .running, scenePhase != .active {
            PhoneNotificationScheduler.schedule(
                plan: timerRuntime.plan,
                from: timerRuntime.currentIndex,
                remaining: timerRuntime.remainingTime
            )
        } else {
            PhoneNotificationScheduler.cancelAll()
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
