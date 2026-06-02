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
    private(set) var state: SessionState = .idle
    private(set) var currentLocation: PhaseLocation?
    private(set) var phaseStartedAt: Date? = nil
    private(set) var remainingTime: Duration = SessionPlan.default.durationA

    private let runtime: TimerRuntime

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self, snapshots = runtime.snapshots] in
            for await snapshot in snapshots {
                self?.state = snapshot.state
                self?.currentLocation = snapshot.currentLocation
                self?.phaseStartedAt = snapshot.phaseStartedAt
                self?.remainingTime = snapshot.remainingTime
            }
        }
    }

    var signals: AsyncStream<TimerSignal> { runtime.signals }

    func restore(from state: RuntimeState) {
        let elapsed = state.wasRunning
            ? Duration(millis: UInt64(max(0, Date().timeIntervalSince(state.phaseStartedAt))) * 1000)
            : state.elapsedInPhase
        Task { await runtime.restore(plan: state.plan, location: state.location, elapsed: elapsed, wasRunning: state.wasRunning) }
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
