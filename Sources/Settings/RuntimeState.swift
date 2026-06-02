import Foundation
import GrainDomain

struct RuntimeState: Codable, Sendable {
    var plan: SessionPlan
    var location: PhaseLocation
    var phaseStartedAt: Date
}
