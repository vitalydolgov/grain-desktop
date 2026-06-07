import GrainDomain
import GrainApplication

/// The user's session configuration: a target total, split into A/B intervals by the planner.
struct PlanConfiguration: Codable, Sendable, Equatable {
    var totalMinutes: Int
    var endWithB: Bool

    static let `default` = PlanConfiguration(totalMinutes: 60, endWithB: true)
}

extension PlanConfiguration {
    private var total: Duration { .minutes(UInt64(totalMinutes)) }

    /// Whether a plan exists for this total ending on the given phase.
    func canPlan(endWithB: Bool) -> Bool {
        SessionPlanner().canPlan(for: total, endWithB: endWithB, ramp: .falling)
    }

    /// Builds the session plan for this configuration, or nil when the total can't be split.
    func makePlan() -> SessionPlan? {
        try? SessionPlanner().plan(for: total, endWithB: endWithB, ramp: .falling)
    }
}
