import GrainApplication

@MainActor
protocol RuntimeCommandHandler: AnyObject {
    func handle(_ command: RuntimeCommand)
}
