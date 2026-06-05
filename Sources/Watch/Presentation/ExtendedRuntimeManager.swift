import WatchKit

@MainActor
final class ExtendedRuntimeManager: NSObject, @MainActor WKExtendedRuntimeSessionDelegate {
    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session?.state != .running, session?.state != .scheduled else { return }
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        self.session = session
        session.start()
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: (any Error)?) {
        if session === extendedRuntimeSession {
            session = nil
        }
    }
}
