import SwiftUI

/// One complete theme: the only things that change between themes are color and elevation.
/// Spacing, radius, type, motion, and z-order are theme-invariant (see `Scales.swift`).
public struct Theme: Sendable, Hashable, Identifiable {
    public var name: String
    /// Light or dark — drives native controls and materials inside the themed subtree.
    public var scheme: ColorScheme
    public var color: Palette
    public var status: StatusPalette
    public var elevation: ElevationScale

    public var id: String { name }

    public init(
        name: String, scheme: ColorScheme, color: Palette, status: StatusPalette,
        elevation: ElevationScale
    ) {
        self.name = name
        self.scheme = scheme
        self.color = color
        self.status = status
        self.elevation = elevation
    }

    /// The shipped themes, in the same order as the web's `ThemeName`.
    public static let all: [Theme] = [.light, .dark, .reliquary]

    /// A tone resolved for this theme, including the legibility-safe `text` role.
    public func tone(_ tone: Tone) -> ToneColors {
        switch tone {
        case .accent:
            // The CSS has no `--tcl-accent-bg`; the web components tint accent at 16%.
            // Pre-composited over `surface` so the tint is opaque, like the status tints.
            // Accent is the one tone whose hover/active are AUTHORED per theme — use them.
            ToneColors(
                base: color.accent, bg: color.accent.opacity(0.16).over(color.surface),
                fg: color.accentFg, text: color.text,
                hover: color.accentHover, pressed: color.accentActive)
        case .neutral:
            ToneColors(
                base: status.neutral.base, bg: status.neutral.bg, fg: status.neutral.fg,
                text: color.textDim)
        case .info: Self.resolve(status.info)
        case .success: Self.resolve(status.success)
        case .warning: Self.resolve(status.warning)
        case .danger: Self.resolve(status.danger)
        }
    }

    private static func resolve(_ status: StatusColors) -> ToneColors {
        ToneColors(base: status.base, bg: status.bg, fg: status.fg, text: status.base)
    }
}

// MARK: - Choosing a theme

/// How a subtree picks its theme.
public enum ThemeChoice: Sendable, Hashable {
    /// Follow the system appearance. This is the default — no setup needed.
    case automatic(light: Theme = .light, dark: Theme = .dark)
    /// Pin one theme regardless of system appearance.
    case fixed(Theme)

    public func resolve(for scheme: ColorScheme) -> Theme {
        switch self {
        case .automatic(let light, let dark): scheme == .dark ? dark : light
        case .fixed(let theme): theme
        }
    }
}

private struct ThemeChoiceKey: EnvironmentKey {
    static let defaultValue: ThemeChoice = .automatic()
}

extension EnvironmentValues {
    public var themeChoice: ThemeChoice {
        get { self[ThemeChoiceKey.self] }
        set { self[ThemeChoiceKey.self] = newValue }
    }

    /// The resolved theme. Derived from `themeChoice` + `colorScheme`, so it updates live
    /// when the system flips between light and dark.
    ///
    ///     @Environment(\.theme) private var theme
    public var theme: Theme { themeChoice.resolve(for: colorScheme) }
}

extension View {
    /// Pin a theme for this subtree. Also sets `colorScheme`, so native controls and
    /// materials inside match. At an app root, add `.preferredColorScheme(theme.scheme)`
    /// too if the window chrome should follow.
    public func trembusTheme(_ theme: Theme) -> some View {
        environment(\.themeChoice, .fixed(theme))
            .environment(\.colorScheme, theme.scheme)
    }

    /// Choose which themes stand for light and dark while following the system:
    /// `.trembusTheme(.automatic(dark: .reliquary))`.
    public func trembusTheme(_ choice: ThemeChoice) -> some View {
        modifier(ThemeChoiceModifier(choice: choice))
    }
}

private struct ThemeChoiceModifier: ViewModifier {
    let choice: ThemeChoice

    func body(content: Content) -> some View {
        switch choice {
        case .automatic: content.environment(\.themeChoice, choice)
        case .fixed(let theme): content.trembusTheme(theme)
        }
    }
}
