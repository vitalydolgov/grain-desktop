import Observation

@MainActor
@Observable
final class AppSettings {
    var configuration: PlanConfiguration = .default
    private let plan: PlanSettings

    init(plan: PlanSettings) {
        self.plan = plan
    }

    func load() async {
        configuration = await plan.load()
    }

    func save() async {
        try? await plan.save(configuration)
    }
}
