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
protocol RuntimeSynchronizerDelegate: RuntimeCommandHandler {
    func restore(timer: TimerSnapshot, plan: SessionPlan)
}

@Observable
@MainActor
final class RuntimeSynchronizer: RuntimeCommandHandler {
    private(set) var syncMode: SyncMode = .none
    var status: SessionStatus = .idle

    nonisolated let commands: AsyncStream<RuntimeCommand>
    private let commandContn: AsyncStream<RuntimeCommand>.Continuation

    private weak var delegate: (any RuntimeSynchronizerDelegate)?

    init(delegate: any RuntimeSynchronizerDelegate) {
        self.delegate = delegate
        (commands, commandContn) = AsyncStream.makeStream(of: RuntimeCommand.self)
        Task { [weak self] in await self?.beginSyncMonitoring() }
    }

    private func beginSyncMonitoring() async {
        for await state in RuntimeConnectivity.states {
            switch state.timer.status {
            case .idle, .completed:
                if case .synced = syncMode { delegate?.handle(.reset) }
                syncMode = .none
            case .running, .paused:
                switch syncMode {
                case .synced:
                    restore(from: state)
                case .none:
                    if status == .idle || status == .completed {
                        syncMode = .pending(state)
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

    func handle(_ command: RuntimeCommand) {
        commandContn.yield(command)
    }
}
