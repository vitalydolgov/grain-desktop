import Foundation
import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class RuntimeProxy {
    private(set) var timer: TimerSnapshot?
    private(set) var status: SessionStatus = .idle
    private(set) var currentIndex: IntervalIndex = IntervalIndex(index: 0)
    private(set) var remainingTime: Duration = .zero
    private(set) var plan: SessionPlan = .empty

    private let runtime: TimerRuntime

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self] in
            for await state in await runtime.makeRuntimeStateStream() {
                guard let self else { break }
                self.timer = state.timer
                self.status = state.timer.status
                self.currentIndex = state.timer.currentIndex
                self.remainingTime = state.timer.remainingTime
                self.plan = state.plan
            }
        }
    }

    func signals() -> AsyncStream<TimerSignal> {
        runtime.signals
    }

    func intents() -> AsyncStream<NotificationIntent> {
        runtime.intents
    }

    func runtimeStates() async -> AsyncStream<RuntimeState> {
        await runtime.makeRuntimeStateStream()
    }

    func restore(from state: RuntimeState) {
        Task { await runtime.restore(timer: state.timer, plan: state.plan) }
    }

    func setPlan(_ plan: SessionPlan) {
        Task { await runtime.setPlan(plan) }
    }

    func handle(_ command: RuntimeCommand) {
        Task { try? await runtime.handle(command) }
    }
}
