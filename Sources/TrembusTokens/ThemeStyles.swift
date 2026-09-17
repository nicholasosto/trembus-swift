import SwiftUI

// Tokens as shape styles. A style resolves against the theme in the environment AT THE
// POINT OF USE, the same way `.tint` and `.primary` do — so components never need
// `@Environment(\.theme)` just to paint:
//
//     Text("Saved").foregroundStyle(.theme(.textDim))
//     Capsule().fill(.tone(.success, .bg))
//
// Reach for `@Environment(\.theme)` only where SwiftUI wants a plain `Color`
// (shadows, Canvas, AppKit interop) or when you need to do color math.

/// A chrome color token, resolved per theme — and per accessibility setting.
public struct ThemeColor: ShapeStyle {
    var token: ColorToken
    var alpha: Double = 1

    public func resolve(in environment: EnvironmentValues) -> Color {
        let effective =
            environment.colorSchemeContrast == .increased ? token.increasedContrast : token
        let value = environment.theme.color[effective]
        return (alpha == 1 ? value : value.opacity(value.alpha * alpha)).color
    }

    /// The same token, more transparent.
    public func opacity(_ alpha: Double) -> ThemeColor {
        ThemeColor(token: token, alpha: self.alpha * alpha)
    }
}

extension ShapeStyle where Self == ThemeColor {
    /// `.theme(.surface)` — a chrome color from the current theme.
    public static func theme(_ token: ColorToken) -> ThemeColor { ThemeColor(token: token) }
}

/// A tone from the color-coded ontology, resolved per theme.
public struct ToneColor: ShapeStyle {
    var tone: Tone
    var role: ToneRole

    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.theme.tone(tone)[role].color
    }
}

extension ShapeStyle where Self == ToneColor {
    /// `.tone(.success)` — solid fill. `.tone(.success, .bg)` — soft tint.
    /// `.tone(.success, .text)` — legibility-safe text.
    public static func tone(_ tone: Tone, _ role: ToneRole = .base) -> ToneColor {
        ToneColor(tone: tone, role: role)
    }
}
