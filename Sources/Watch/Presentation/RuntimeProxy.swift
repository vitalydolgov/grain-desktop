import Foundation
import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class RuntimeProxy: RuntimeSynchronizerDelegate {
    private(set) var status: SessionStatus = .idle
    private(set) var currentIndex: IntervalIndex = IntervalIndex(index: 0)
    private(set) var remainingTime: Duration = .zero
    private(set) var plan: SessionPlan = .empty

    nonisolated let statuses: AsyncStream<SessionStatus>
    private let statusContn: AsyncStream<SessionStatus>.Continuation

    private let runtime: TimerRuntime

    init(runtime: TimerRuntime) {
        self.runtime = runtime
        let (stream, contn) = AsyncStream.makeStream(of: SessionStatus.self)
        self.statuses = stream
        self.statusContn = contn
        Task { [weak self] in
            for await state in await runtime.makeRuntimeStateStream() {
                guard let self else { break }
                let newStatus = state.timer.status
                if newStatus != self.status {
                    self.statusContn.yield(newStatus)
                }
                self.status = newStatus
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

    func restore(timer: TimerSnapshot, plan: SessionPlan) {
        Task { await runtime.restore(timer: timer, plan: plan) }
    }

    func setPlan(_ plan: SessionPlan) {
        Task { await runtime.setPlan(plan) }
    }

    func handle(_ command: RuntimeCommand) {
        Task { try? await runtime.handle(command) }
    }
}
