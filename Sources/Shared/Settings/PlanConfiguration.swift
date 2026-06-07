import GrainDomain
import GrainApplication

struct PlanConfiguration: Codable, Sendable, Equatable {
    var totalMinutes: Int
    var endWithB: Bool

    static let `default` = PlanConfiguration(totalMinutes: 60, endWithB: true)
}

extension PlanConfiguration {
    private var total: Duration { .minutes(UInt64(totalMinutes)) }

    func canPlan(endWithB: Bool) -> Bool {
        SessionPlanner().canPlan(for: total, endWithB: endWithB, ramp: .falling)
    }

    var isFeasible: Bool {
        canPlan(endWithB: endWithB)
    }

    func makePlan() -> SessionPlan? {
        try? SessionPlanner().plan(for: total, endWithB: endWithB, ramp: .falling)
    }
}
