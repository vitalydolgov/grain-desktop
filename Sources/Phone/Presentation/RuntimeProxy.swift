import Foundation
import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class RuntimeProxy {
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
                self.status = state.timer.status
                self.currentIndex = state.timer.currentIndex
                self.remainingTime = state.timer.remainingTime
                self.plan = state.plan
            }
        }
    }

    // MARK: Streams

    func signals() -> AsyncStream<TimerSignal> {
        runtime.signals
    }

    // MARK: Commands

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
