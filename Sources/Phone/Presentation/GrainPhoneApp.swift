import SwiftUI
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
                    try? await PhoneNotification.requestAuthorization()
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
                    await PhoneNotification.realize(intents: timerRuntime.intents())
                }
                .task {
                    var lastKey = ""
                    for await state in await timerRuntime.runtimeStates() {
                        let key = "\(state.timer.status)-\(state.timer.currentIndex.index)"
                        guard key != lastKey else { continue }
                        lastKey = key
                        await LiveActivityService.update(from: state)
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
