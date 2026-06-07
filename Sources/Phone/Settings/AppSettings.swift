import Observation

@MainActor
@Observable
final class AppSettings {
    let plan: PlanSettings

    init(plan: PlanSettings) {
        self.plan = plan
    }
}
