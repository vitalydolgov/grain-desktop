import Observation
import GrainDomain
import GrainApplication

enum SyncMode: Sendable {
    case none
    case pending(RuntimeStateSync.Source, RuntimeState)
    case declined(RuntimeStateSync.Source)
    case synced(RuntimeStateSync.Source)
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

    var pendingSource: RuntimeStateSync.Source? {
        if case .pending(let source, _) = syncMode { source } else { nil }
    }

    private func beginSyncMonitoring() async {
        await withTaskGroup(of: Void.self) { group in
            for source in RuntimeStateSync.Source.allCases {
                let subscriber = RuntimeStateSync.wearableSubscriber(following: source)
                group.addTask { [weak self] in
                    for await state in subscriber.states {
                        await self?.handle(state, from: source)
                    }
                }
            }
        }
    }

    private func handle(_ remoteState: RuntimeState, from source: RuntimeStateSync.Source) {
        let isActive = remoteState.timer.status == .running || remoteState.timer.status == .paused
        switch syncMode {
        case .synced(let s) where s == source:
            if isActive { restore(from: remoteState) } else { reset(); syncMode = .none }
        case .pending(let s, _) where s == source:
            syncMode = isActive ? .pending(source, remoteState) : .none
        case .declined(let s) where s == source:
            if !isActive { syncMode = .none }
        case .none:
            if isActive, status == .idle || status == .completed {
                syncMode = .pending(source, remoteState)
            }
        default:
            break // engaged with a different source; ignore until it goes idle
        }
    }

    func acceptSync() {
        guard case .pending(let source, let state) = syncMode else { return }
        syncMode = .synced(source)
        restore(from: state)
    }

    func declineSync() {
        guard case .pending(let source, _) = syncMode else { return }
        syncMode = .declined(source)
    }

    private func restore(from state: RuntimeState) {
        delegate?.restore(timer: state.timer, plan: state.plan)
    }

    private func reset() {
        delegate?.reset()
    }
}
