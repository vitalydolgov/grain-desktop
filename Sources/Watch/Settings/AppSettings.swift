import Observation

@MainActor
@Observable
final class AppSettings {
    let plan: PlanSettings
    var planConfiguration: PlanConfiguration = .default

    init(plan: PlanSettings) {
        self.plan = plan
    }

    func load() async {
        planConfiguration = await plan.load()
    }

    func save() async {
        try? await plan.save(planConfiguration)
    }
}
