import GrainDomain

protocol SettingsStore: Sendable {
    func load() async throws -> SessionPlan?
    func save(_ plan: SessionPlan) async throws
}
