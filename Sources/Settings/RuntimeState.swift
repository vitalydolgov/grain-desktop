import Foundation
import GrainDomain

struct RuntimeState: Codable, Sendable {
    var plan: SessionPlan
    var location: PhaseLocation
    var phaseStartedAt: Date
    var elapsedInPhase: Duration
    var wasRunning: Bool

    init(plan: SessionPlan, location: PhaseLocation, phaseStartedAt: Date, elapsedInPhase: Duration, wasRunning: Bool) {
        self.plan = plan
        self.location = location
        self.phaseStartedAt = phaseStartedAt
        self.elapsedInPhase = elapsedInPhase
        self.wasRunning = wasRunning
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plan = try c.decode(SessionPlan.self, forKey: .plan)
        location = try c.decode(PhaseLocation.self, forKey: .location)
        phaseStartedAt = try c.decode(Date.self, forKey: .phaseStartedAt)
        wasRunning = try c.decode(Bool.self, forKey: .wasRunning)
        elapsedInPhase = try c.decodeIfPresent(Duration.self, forKey: .elapsedInPhase)
            ?? Duration(millis: UInt64(max(0, Date().timeIntervalSince(phaseStartedAt))) * 1000)
    }
}
