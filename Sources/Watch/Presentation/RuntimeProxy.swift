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
    private let runtimeSession = ExtendedRuntimeManager()

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self] in
            for await state in await runtime.makeRuntimeStateStream() {
                guard let self else { break }
                let newStatus = state.timer.status
                if newStatus != self.status {
                    self.updateSession(for: newStatus)
                }
                self.status = newStatus
                self.currentLocation = state.timer.currentLocation
                self.remainingTime = state.timer.remainingTime
                self.plan = state.plan
            }
        }
    }

    private func updateSession(for status: SessionStatus) {
        switch status {
        case .running:
            runtimeSession.start()
        case .idle, .paused, .completed:
            runtimeSession.stop()
        }
    }

    func signals() -> AsyncStream<TimerSignal> {
        runtime.signals
    }

    func restore(from state: RuntimeState) {
        Task { await runtime.restore(timer: state.timer, plan: state.plan) }
    }

    func setPlan(_ plan: SessionPlan) {
        Task { await runtime.setPlan(plan) }
    }

    func start() {
        let plan = plan
        Task { try? await runtime.start(plan: plan) }
    }

    func pause() {
        Task { try? await runtime.pause() }
    }

    func resume() {
        Task { try? await runtime.resume() }
    }

    func reset() {
        Task { await runtime.reset() }
    }
}
