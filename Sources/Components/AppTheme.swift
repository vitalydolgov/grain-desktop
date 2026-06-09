import SwiftUI
import GrainDomain

public protocol SplitBarTheme {
    func color(for tag: IntervalTag) -> Color
    var labelColor: Color { get }
}

public protocol AppThemeFactory {
    func splitBarTheme(for scheme: ColorScheme) -> any SplitBarTheme
}

@Observable
public final class AppTheme {
    public var colorScheme: ColorScheme = .light
    @ObservationIgnored private let factory: any AppThemeFactory

    public init(_ factory: any AppThemeFactory) {
        self.factory = factory
    }

    public var splitBarTheme: any SplitBarTheme {
        factory.splitBarTheme(for: colorScheme)
    }
}

public extension View {
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
