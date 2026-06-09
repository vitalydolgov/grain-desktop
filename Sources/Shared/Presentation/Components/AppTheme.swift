import SwiftUI
import GrainDomain

protocol SplitBarTheme {
    func color(for tag: IntervalTag) -> Color
    var labelColor: Color { get }
}

protocol AppThemeFactory {
    func splitBarTheme(for scheme: ColorScheme) -> any SplitBarTheme
}

@Observable
final class AppTheme {
    var colorScheme: ColorScheme = .light
    @ObservationIgnored private let factory: any AppThemeFactory

    init(_ factory: any AppThemeFactory) {
        self.factory = factory
    }

    var splitBarTheme: any SplitBarTheme {
        factory.splitBarTheme(for: colorScheme)
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        modifier(AppThemeModifier(theme: theme))
    }
}

private struct AppThemeModifier: ViewModifier {
    let theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(theme)
            .onChange(of: colorScheme, initial: true) { _, scheme in
                theme.colorScheme = scheme
            }
    }
}
