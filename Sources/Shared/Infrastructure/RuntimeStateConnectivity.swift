#if canImport(WatchConnectivity)
import Foundation
import Synchronization
import WatchConnectivity
import GrainApplication

private final class ConnectivitySession: NSObject, WCSessionDelegate, Sendable {
    static let shared = ConnectivitySession()

    private let isSupported: Bool
    private let pending = Mutex<RuntimeState?>(nil)
    private let pendingCommand = Mutex<RuntimeCommand?>(nil)
    private let commandSeq = Mutex<Int>(0)

    let states: AsyncStream<RuntimeState>
    private let stateContn: AsyncStream<RuntimeState>.Continuation

    let commands: AsyncStream<RuntimeCommand>
    private let commandContn: AsyncStream<RuntimeCommand>.Continuation

    private override init() {
        (states, stateContn) = AsyncStream.makeStream(of: RuntimeState.self)
        (commands, commandContn) = AsyncStream.makeStream(of: RuntimeCommand.self)
        isSupported = WCSession.isSupported()
        super.init()
        guard isSupported else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func publish(state: RuntimeState) {
        guard isSupported else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            pending.withLock { $0 = state }
            return
        }
        send(state: state, over: session)
    }

    func publish(command: RuntimeCommand) {
        guard isSupported else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            pendingCommand.withLock { $0 = command }
            return
        }
        send(command: command, over: session)
    }

    private func send(state: RuntimeState, over session: WCSession) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? session.updateApplicationContext(["state": data])
    }

    private func send(command: RuntimeCommand, over session: WCSession) {
        guard let data = try? JSONEncoder().encode(command) else { return }
        let seq = commandSeq.withLock { $0 += 1; return $0 }
        try? session.updateApplicationContext(["command": data, "seq": seq])
    }

    private func lastReceivedState() -> RuntimeState? {
        guard isSupported,
              let data = WCSession.default.receivedApplicationContext["state"] as? Data else { return nil }
        return try? JSONDecoder().decode(RuntimeState.self, from: data)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        guard activationState == .activated else { return }
        let flush = pending.withLock { pending -> RuntimeState? in
            defer { pending = nil }
            return pending
        }
        if let flush { send(state: flush, over: session) }
        let flushCommand = pendingCommand.withLock { pending -> RuntimeCommand? in
            defer { pending = nil }
            return pending
        }
        if let flushCommand { send(command: flushCommand, over: session) }
    }

    private func decodeState(_ context: [String: Any]) -> RuntimeState? {
        guard let data = context["state"] as? Data else { return nil }
        return try? JSONDecoder().decode(RuntimeState.self, from: data)
    }

    private func decodeCommand(_ context: [String: Any]) -> RuntimeCommand? {
        guard let data = context["command"] as? Data else { return nil }
        return try? JSONDecoder().decode(RuntimeCommand.self, from: data)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let state = decodeState(applicationContext) {
            stateContn.yield(state)
        }
        if let command = decodeCommand(applicationContext) {
            commandContn.yield(command)
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}

enum RuntimeConnectivity {

    // MARK: States

    private struct StatePublisher: RuntimePublisher {
        func publish(_ value: RuntimeState) {
            ConnectivitySession.shared.publish(state: value)
        }
    }

    private struct StateSubscriber: RuntimeSubscriber {
        let stream: AsyncStream<RuntimeState>

        init() {
            stream = ConnectivitySession.shared.states
        }
    }

    static var statePublisher: any RuntimePublisher<RuntimeState> {
        StatePublisher()
    }

    static var states: AsyncStream<RuntimeState> {
        StateSubscriber().stream
    }

    // MARK: Commands

    private struct CommandPublisher: RuntimePublisher {
        func publish(_ value: RuntimeCommand) {
            ConnectivitySession.shared.publish(command: value)
        }
    }

    private struct CommandSubscriber: RuntimeSubscriber {
        let stream: AsyncStream<RuntimeCommand>

        init() {
            stream = ConnectivitySession.shared.commands
        }
    }

    static var commandPublisher: any RuntimePublisher<RuntimeCommand> {
        CommandPublisher()
    }

    static var commands: AsyncStream<RuntimeCommand> {
        CommandSubscriber().stream
    }
}
#endif
