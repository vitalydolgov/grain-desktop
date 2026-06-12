import Observation

@MainActor
@Observable
final class AppSettings {
    let plan: PlanSettings
    let runtimeState: RuntimeStateSettings
    var configuration: PlanConfiguration = .default

    init(plan: PlanSettings, runtimeState: RuntimeStateSettings) {
        self.plan = plan
        self.runtimeState = runtimeState
    }

    func load() async {
        configuration = await plan.load()
    }

    func save() async {
        try? await plan.save(configuration)
    }
}
