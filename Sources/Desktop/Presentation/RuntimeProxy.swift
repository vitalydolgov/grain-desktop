import Foundation
import Observation
import GrainDomain
import GrainApplication
import GrainComponents

@Observable
@MainActor
final class RuntimeProxy {
    var plan: SessionPlan = .empty {
        didSet {
            Task { await runtime.setPlan(plan) }
        }
    }
    private(set) var timer: TimerSnapshot?
    private(set) var status: SessionStatus = .idle
    private(set) var currentIndex: IntervalIndex = IntervalIndex(index: 0)
    private(set) var intervalStartedAt: Date? = nil
    private(set) var remainingTime: Duration = .zero

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
                self.intervalStartedAt = state.timer.intervalStartedAt
                self.remainingTime = state.timer.remainingTime
            }
        }
    }

    func signals() -> AsyncStream<TimerSignal> {
        runtime.signals
    }

    func runtimeStates() async -> AsyncStream<RuntimeState> {
        await runtime.makeRuntimeStateStream()
    }

    func restore(from state: RuntimeState) {
        Task { await runtime.restore(timer: state.timer, plan: state.plan) }
    }
}

extension RuntimeProxy: RuntimeControlProtocol {
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

    func skip() {
        Task { try? await runtime.skip() }
    }

    func reset() {
        Task { await runtime.reset() }
    }
}
