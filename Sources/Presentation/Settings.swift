import GrainDomain

typealias Duration = GrainDomain.Duration

struct Settings {
    var partAName: String
    var partBName: String
    var partADuration: Duration
    var partBDuration: Duration
    var totalRounds: Int

    static let defaultPartAName = "Work"
    static let defaultPartBName = "Break"
    static let defaultTotalRounds = 4

    init(
        partAName: String = defaultPartAName,
        partBName: String = defaultPartBName,
        partADuration: Duration = .seconds(25 * 60),
        partBDuration: Duration = .seconds(5 * 60),
        totalRounds: Int = defaultTotalRounds
    ) {
        self.partAName = partAName
        self.partBName = partBName
        self.partADuration = partADuration
        self.partBDuration = partBDuration
        self.totalRounds = totalRounds
    }

    func makePlan() -> SessionPlan {
        SessionPlan(durationA: partADuration, durationB: partBDuration, totalRounds: totalRounds)
    }
}
