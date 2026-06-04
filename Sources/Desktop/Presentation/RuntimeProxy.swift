import Foundation
import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class RuntimeProxy {
    var plan: SessionPlan = .default {
        didSet {
            Task { await runtime.setPlan(plan) }
        }
    }
    private(set) var timer: TimerSnapshot?
    private(set) var status: SessionStatus = .idle
    private(set) var currentLocation: PhaseLocation?
    private(set) var phaseStartedAt: Date? = nil
    private(set) var remainingTime: Duration = SessionPlan.default.durationA

    private let runtime: TimerRuntime

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self] in
            for await state in await runtime.makeRuntimeStateStream() {
                guard let self else { break }
                self.timer = state.timer
                self.status = state.timer.status
                self.currentLocation = state.timer.currentLocation
                self.phaseStartedAt = state.timer.phaseStartedAt
                self.remainingTime = state.timer.remainingTime
            }
        }
    }

    // MARK: Streams

    func signals() -> AsyncStream<TimerSignal> {
        runtime.signals
    }

    func runtimeStates() async -> AsyncStream<RuntimeState> {
        await runtime.makeRuntimeStateStream()
    }

    // MARK: Commands

    func restore(from state: RuntimeState) {
        Task { await runtime.restore(timer: state.timer, plan: state.plan) }
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
