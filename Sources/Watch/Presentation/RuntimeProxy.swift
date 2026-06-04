import Foundation
import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class RuntimeProxy {
    private(set) var status: SessionStatus = .idle
    private(set) var currentLocation: PhaseLocation?
    private(set) var remainingTime: Duration = SessionPlan.default.durationA
    private(set) var plan: SessionPlan = .default

    private let runtime: TimerRuntime

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self] in
            for await state in await runtime.makeRuntimeStateStream() {
                guard let self else { break }
                self.status = state.timer.status
                self.currentLocation = state.timer.currentLocation
                self.remainingTime = state.timer.remainingTime
                self.plan = state.plan
            }
        }
    }

    func restore(from state: RuntimeState) {
        Task { await runtime.restore(timer: state.timer, plan: state.plan) }
    }
}
