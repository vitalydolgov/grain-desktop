import Observation
import GrainDomain
import GrainApplication

@Observable
@MainActor
final class TimerRuntimeBridge {
    var plan: SessionPlan = .default {
        didSet {
            let newPlan = plan
            Task { await runtime.setPlan(newPlan) }
        }
    }
    private(set) var state: SessionState = .idle
    private(set) var currentLocation: PhaseLocation?
    private(set) var elapsedInPhase: Duration = .zero
    private(set) var remainingTime: Duration = SessionPlan.default.durationA

    private let runtime: TimerRuntime

    init(clock: any ClockSource = SystemClock()) {
        let runtime = TimerRuntime(clock: clock)
        self.runtime = runtime
        Task { [weak self, snapshots = runtime.snapshots] in
            for await snapshot in snapshots {
                self?.apply(snapshot)
            }
        }
    }

    private func apply(_ snapshot: TimerSnapshot) {
        state = snapshot.state
        currentLocation = snapshot.currentLocation
        elapsedInPhase = snapshot.elapsedInPhase
        remainingTime = snapshot.remainingTime
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
