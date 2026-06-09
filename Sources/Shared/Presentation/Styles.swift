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
