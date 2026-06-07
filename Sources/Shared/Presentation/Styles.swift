import SwiftUI
import GrainDomain

extension Font {
    static func customMonospaced(size: CGFloat) -> Font {
        .custom("SUSE Mono", size: size)
    }

    static func customRegular(size: CGFloat) -> Font {
        .custom("Urbanist", size: size)
    }
}

extension IntervalTag {
    var color: Color {
        switch self {
        case .a: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .b: Color(red: 0.96, green: 0.72, blue: 0.16)
        }
    }

    var label: String {
        switch self {
        case .a: "Focus"
        case .b: "Break"
        }
    }
}

enum TimerFace: Equatable {
    case ready
    case active(IntervalTag)

    init(status: SessionStatus, tag: IntervalTag?) {
        switch status {
        case .running, .paused:
            self = tag.map(TimerFace.active) ?? .ready
        case .idle, .completed:
            self = .ready
        }
    }

    var label: String {
        switch self {
        case .ready: "Ready"
        case .active(let tag): tag.label
        }
    }
}
