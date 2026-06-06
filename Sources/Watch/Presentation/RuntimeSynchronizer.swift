import Observation
import GrainDomain
import GrainApplication

enum SyncMode: Sendable {
    case none
    case pending(RuntimeState)
    case declined
    case synced
}

@MainActor
protocol RuntimeSynchronizerDelegate: AnyObject {
    func restore(timer: TimerSnapshot, plan: SessionPlan)
    func reset()
}

@Observable
@MainActor
final class RuntimeSynchronizer {
    private(set) var syncMode: SyncMode = .none
    var status: SessionStatus = .idle

    private weak var delegate: (any RuntimeSynchronizerDelegate)?

    init(delegate: any RuntimeSynchronizerDelegate) {
        self.delegate = delegate
        Task { [weak self] in await self?.beginSyncMonitoring() }
    }

    private func beginSyncMonitoring() async {
        let subscriber = RuntimeStateSync.wearableSubscriber(following: .desktop)
        for await remoteState in subscriber.states {
            switch remoteState.timer.status {
            case .idle, .completed:
                if case .synced = syncMode { reset() }
                syncMode = .none
            case .running, .paused:
                switch syncMode {
                case .synced:
                    restore(from: remoteState)
                case .none:
                    if status == .idle || status == .completed {
                        syncMode = .pending(remoteState)
                    }
                case .pending, .declined:
                    break
                }
            }
        }
    }

    func acceptSync() {
        guard case .pending(let state) = syncMode else { return }
        syncMode = .synced
        restore(from: state)
    }

    func declineSync() {
        guard case .pending = syncMode else { return }
        syncMode = .declined
    }

    private func restore(from state: RuntimeState) {
        delegate?.restore(timer: state.timer, plan: state.plan)
    }

    private func reset() {
        delegate?.reset()
    }
}
