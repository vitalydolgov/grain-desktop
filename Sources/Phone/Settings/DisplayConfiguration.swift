struct DisplayConfiguration: Codable, Sendable, Equatable {
    var keepScreenOn: Bool

    static let `default` = DisplayConfiguration(keepScreenOn: false)
}
