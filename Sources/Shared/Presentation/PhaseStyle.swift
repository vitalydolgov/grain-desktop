import SwiftUI
import GrainDomain

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
