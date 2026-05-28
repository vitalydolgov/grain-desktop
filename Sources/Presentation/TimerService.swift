import Observation
import GrainDomain
import GrainApplication

@Observable @MainActor
final class TimerService {
    private(set) var runState: RunState = .idle
    private(set) var currentLocation: PhaseLocation?
    private(set) var elapsedInPhase: Duration = .zero
    var settings: Settings = Settings()

    private var runner: SessionRunner?
    private var plan: SessionPlan?
    private var eventTask: Task<Void, Never>?
    private var displayTask: Task<Void, Never>?

    var remainingTime: Duration {
        guard let plan, let location = currentLocation else { return settings.partADuration }
        let phaseDuration = location.kind == .a ? plan.durationA : plan.durationB
        return phaseDuration - elapsedInPhase
    }

    func start() async throws {
        let newPlan = settings.makePlan()
        let r = SessionRunner(plan: newPlan)
        runner = r
        plan = newPlan
        try await r.start()
        subscribeToEvents(r)
        startDisplayUpdates(r)
    }

    func pause() async throws {
        try await runner?.pause()
        displayTask?.cancel()
        displayTask = nil
    }

    func resume() async throws {
        guard let r = runner else { return }
        try await r.resume()
        startDisplayUpdates(r)
    }

    func reset() async throws {
        try await runner?.reset()
        clear()
    }

    private func clear() {
        eventTask?.cancel()
        displayTask?.cancel()
        eventTask = nil
        displayTask = nil
        runner = nil
        plan = nil
        runState = .idle
        currentLocation = nil
        elapsedInPhase = .zero
    }

    private func subscribeToEvents(_ r: SessionRunner) {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            for await _ in r.events {
                guard let self else { break }
                let state = await r.runState
                let location = await r.currentLocation
                let elapsed = await r.elapsedInPhase
                self.runState = state
                self.currentLocation = location
                self.elapsedInPhase = elapsed
                if state == .completed || state == .idle {
                    self.displayTask?.cancel()
                    self.displayTask = nil
                }
            }
        }
    }

    private func startDisplayUpdates(_ r: SessionRunner) {
        displayTask?.cancel()
        displayTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, let self else { break }
                let elapsed = await r.elapsedInPhase
                self.elapsedInPhase = elapsed
            }
        }
    }
}
