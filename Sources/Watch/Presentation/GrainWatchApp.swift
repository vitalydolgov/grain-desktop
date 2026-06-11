import SwiftUI
import WatchKit
import GrainApplication
import GrainComponents

@main
struct GrainWatchApp: App {
    @State private var settings = AppSettings(plan: PlanSettings(store: UserDefaultsPlanSettingsStore()))
    @State private var theme = AppTheme(WatchThemeFactory())
    @State private var timerRuntime: RuntimeProxy
    @State private var synchronizer: RuntimeSynchronizer
    private let extendedOSSession = ExtendedOSSession()

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
                .environment(settings)
                .appTheme(theme)
                .task {
                    await settings.load()
                    if let plan = settings.configuration.makePlan() {
                        timerRuntime.setPlan(plan)
                    }
                }
                .task {
                    for await command in synchronizer.commands {
                        RuntimeConnectivity.commandPublisher.publish(command)
                    }
                }
                .task {
                    for await signal in timerRuntime.signals() {
                        switch signal {
                        case .intervalCompleted:
                            WKInterfaceDevice.current().play(.notification)
                        case .sessionCompleted, .sessionCompletedWhileAway:
                            WKInterfaceDevice.current().play(.success)
                        case .sessionRestored:
                            break
                        }
                    }
                }
                .task {
                    for await status in timerRuntime.statuses {
                        synchronizer.status = status
                        switch status {
                        case .running: extendedOSSession.start()
                        case .idle, .paused, .completed: extendedOSSession.stop()
                        }
                    }
                }
        }
    }
}
