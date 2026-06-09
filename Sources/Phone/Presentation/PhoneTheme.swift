import SwiftUI
import GrainDomain
import GrainComponents

struct PhoneThemeFactory: AppThemeFactory {
    func splitBarTheme(for scheme: ColorScheme) -> any SplitBarTheme {
        PhoneSplitBarTheme(colorScheme: scheme)
    }
}

private struct PhoneSplitBarTheme: SplitBarTheme {
    let colorScheme: ColorScheme

    func color(for tag: IntervalTag) -> Color {
        tag.splitBarColor(for: colorScheme)
    }

    var labelColor: Color { .primary }
}

struct PhaseTheme {
    let background: LinearGradient
    let accentColor: Color
    let labelColor: Color
    let timerTextColor: Color
    let controlSurfaceColor: Color
    let controlIconColor: Color
    let onAccentColor: Color

    static func idle(_ scheme: ColorScheme) -> PhaseTheme {
        scheme == .dark ? idleDark : idleLight
    }

    private static let idleLight = PhaseTheme(
        background: LinearGradient(
            colors: [Color(red: 0.93, green: 0.94, blue: 0.96),
                     Color(red: 0.85, green: 0.88, blue: 0.92)],
            startPoint: .top, endPoint: .bottom),
        accentColor: Color(red: 0.40, green: 0.45, blue: 0.53),
        labelColor: Color(red: 0.44, green: 0.49, blue: 0.56),
        timerTextColor: Color(red: 0.27, green: 0.32, blue: 0.39),
        controlSurfaceColor: Color(red: 0.95, green: 0.96, blue: 0.98),
        controlIconColor: Color(red: 0.40, green: 0.45, blue: 0.53),
        onAccentColor: .white)

    private static let idleDark = PhaseTheme(
        background: .descending(Color(red: 0.09, green: 0.11, blue: 0.14)),
        accentColor: Color(red: 0.62, green: 0.67, blue: 0.74),
        labelColor: Color(red: 0.62, green: 0.67, blue: 0.74),
        timerTextColor: Color(white: 0.96),
        controlSurfaceColor: Color.white.opacity(0.08),
        controlIconColor: Color.white.opacity(0.6),
        onAccentColor: Color(white: 0.08))
}

extension TimerFace {
    func theme(_ scheme: ColorScheme) -> PhaseTheme {
        switch self {
        case .ready: .idle(scheme)
        case .active(let tag): tag.theme(scheme)
        }
    }
}

extension IntervalTag {
    func theme(_ scheme: ColorScheme) -> PhaseTheme {
        scheme == .dark ? darkTheme : lightTheme
    }

    func splitBarColor(for scheme: ColorScheme) -> Color {
        let base: Color = switch self {
        case .a: Color(red: 0.67, green: 0.82, blue: 0.98)
        case .b: Color(red: 0.94, green: 0.84, blue: 0.57)
        }
        return scheme == .dark ? base.opacity(0.5) : base
    }

    private var lightTheme: PhaseTheme {
        switch self {
        case .a:
            PhaseTheme(
                background: LinearGradient(
                    colors: [Color(red: 0.80, green: 0.89, blue: 0.99),
                             Color(red: 0.67, green: 0.82, blue: 0.98)],
                    startPoint: .top, endPoint: .bottom),
                accentColor: Color(red: 0.09, green: 0.45, blue: 0.86),
                labelColor: Color(red: 0.09, green: 0.45, blue: 0.86),
                timerTextColor: Color(red: 0.12, green: 0.23, blue: 0.38),
                controlSurfaceColor: Color(red: 0.91, green: 0.95, blue: 0.99),
                controlIconColor: Color(red: 0.29, green: 0.41, blue: 0.55),
                onAccentColor: .white)
        case .b:
            PhaseTheme(
                background: LinearGradient(
                    colors: [Color(red: 0.98, green: 0.93, blue: 0.78),
                             Color(red: 0.94, green: 0.84, blue: 0.57)],
                    startPoint: .top, endPoint: .bottom),
                accentColor: Color(red: 0.78, green: 0.51, blue: 0.05),
                labelColor: Color(red: 0.72, green: 0.46, blue: 0.04),
                timerTextColor: Color(red: 0.36, green: 0.24, blue: 0.11),
                controlSurfaceColor: Color(red: 0.98, green: 0.95, blue: 0.86),
                controlIconColor: Color(red: 0.45, green: 0.34, blue: 0.16),
                onAccentColor: .white)
        }
    }

    private var darkTheme: PhaseTheme {
        switch self {
        case .a:
            PhaseTheme(
                background: .descending(Color(red: 0.05, green: 0.10, blue: 0.20)),
                accentColor: Color(red: 0.23, green: 0.62, blue: 1.0),
                labelColor: Color(red: 0.23, green: 0.62, blue: 1.0),
                timerTextColor: Color(white: 0.96),
                controlSurfaceColor: Color.white.opacity(0.08),
                controlIconColor: Color.white.opacity(0.6),
                onAccentColor: Color(white: 0.08))
        case .b:
            PhaseTheme(
                background: .descending(Color(red: 0.16, green: 0.115, blue: 0.035)),
                accentColor: Color(red: 0.96, green: 0.72, blue: 0.16),
                labelColor: Color(red: 0.96, green: 0.72, blue: 0.16),
                timerTextColor: Color(red: 0.96, green: 0.94, blue: 0.87),
                controlSurfaceColor: Color.white.opacity(0.08),
                controlIconColor: Color.white.opacity(0.6),
                onAccentColor: Color(white: 0.08))
        }
    }
}

private extension LinearGradient {
    static func descending(_ tint: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: tint, location: 0),
                .init(color: .black, location: 0.78)
            ],
            startPoint: .top, endPoint: .bottom)
    }
}
