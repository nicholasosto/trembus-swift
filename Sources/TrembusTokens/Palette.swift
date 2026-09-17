import SwiftUI

/// The chrome colors of one theme. Names mirror the web tokens one-for-one:
/// `surfaceRaised` ↔ `--tcl-surface-raised`.
public struct Palette: Sendable, Hashable {
    public var bg: ColorValue
    public var surface: ColorValue
    public var surfaceRaised: ColorValue
    public var surfaceSunken: ColorValue
    public var surfaceHover: ColorValue
    public var overlay: ColorValue

    public var border: ColorValue
    public var borderSoft: ColorValue
    public var borderStrong: ColorValue

    public var text: ColorValue
    public var textDim: ColorValue
    public var textFaint: ColorValue

    public var accent: ColorValue
    public var accentHover: ColorValue
    public var accentActive: ColorValue
    public var accentFg: ColorValue
    public var focusRing: ColorValue

    public subscript(token: ColorToken) -> ColorValue {
        switch token {
        case .bg: bg
        case .surface: surface
        case .surfaceRaised: surfaceRaised
        case .surfaceSunken: surfaceSunken
        case .surfaceHover: surfaceHover
        case .overlay: overlay
        case .border: border
        case .borderSoft: borderSoft
        case .borderStrong: borderStrong
        case .text: text
        case .textDim: textDim
        case .textFaint: textFaint
        case .accent: accent
        case .accentHover: accentHover
        case .accentActive: accentActive
        case .accentFg: accentFg
        case .focusRing: focusRing
        }
    }
}

/// Type-safe names for the chrome colors. Components say `.theme(.surface)` — never a hex.
public enum ColorToken: String, CaseIterable, Sendable {
    case bg, surface, surfaceRaised, surfaceSunken, surfaceHover, overlay
    case border, borderSoft, borderStrong
    case text, textDim, textFaint
    case accent, accentHover, accentActive, accentFg, focusRing

    /// The matching CSS custom property in `@trembus/tokens`, for cross-reference.
    public var cssName: String {
        let kebab = rawValue.reduce(into: "") { out, ch in
            if ch.isUppercase { out += "-" + ch.lowercased() } else { out.append(ch) }
        }
        return "--tcl-" + kebab
    }

    /// What this token becomes when the user turns on **Increase Contrast**:
    /// edges and quiet text each step up one notch. Everything else is unchanged.
    public var increasedContrast: ColorToken {
        switch self {
        case .borderSoft: .border
        case .border: .borderStrong
        case .textFaint: .textDim
        case .textDim: .text
        default: self
        }
    }
}
