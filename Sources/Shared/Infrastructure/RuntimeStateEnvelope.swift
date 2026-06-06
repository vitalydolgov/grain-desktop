import Foundation
import GrainApplication

struct RuntimeStateEnvelope: Codable {
    let state: RuntimeState
    let publishedAt: TimeInterval

    init(_ state: RuntimeState) {
        self.state = state
        self.publishedAt = Date().timeIntervalSinceReferenceDate
    }
}
