import SwiftUI
import GrainDomain
import GrainComponents

struct DesktopThemeFactory: AppThemeFactory {
    func splitBarTheme(for scheme: ColorScheme) -> any SplitBarTheme {
        DesktopSplitBarTheme()
    }
}

private struct DesktopSplitBarTheme: SplitBarTheme {
    func color(for tag: IntervalTag) -> Color {
        switch tag {
        case .a: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .b: Color(red: 0.96, green: 0.72, blue: 0.16)
        }
    }

    var labelColor: Color { .white }
}
