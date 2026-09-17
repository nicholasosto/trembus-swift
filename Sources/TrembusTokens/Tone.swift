import SwiftUI

/// The color-coded ontology: six hues that always mean the same thing.
/// Same vocabulary as `Tone` in `@trembus/tokens`.
public enum Tone: String, CaseIterable, Sendable {
    case accent, info, success, warning, danger, neutral
}

/// Which part of a tone you are painting.
public enum ToneRole: String, CaseIterable, Sendable {
    /// Solid fill or stroke.
    case base
    /// Soft opaque tint behind content.
    case bg
    /// Ink that sits ON a solid `base` fill.
    case fg
    /// The tone painted AS text on the page. Legibility-safe: accent → `text`,
    /// neutral → `textDim`, statuses keep their hue (gold-on-white is ~2:1, so
    /// accent never paints text directly).
    case text
}

/// One tone, resolved for one theme.
public struct ToneColors: Sendable, Hashable {
    public var base: ColorValue
    public var bg: ColorValue
    public var fg: ColorValue
    public var text: ColorValue
    /// Solid fill under the pointer.
    public var hover: ColorValue
    /// Solid fill while pressed.
    public var pressed: ColorValue

    /// Leave `hover` / `pressed` nil to derive them (see `steppedAwayFromInk`).
    public init(
        base: ColorValue, bg: ColorValue, fg: ColorValue, text: ColorValue,
        hover: ColorValue? = nil, pressed: ColorValue? = nil
    ) {
        self.base = base
        self.bg = bg
        self.fg = fg
        self.text = text
        self.hover = hover ?? Self.steppedAwayFromInk(base, ink: fg, by: 0.14)
        self.pressed = pressed ?? Self.steppedAwayFromInk(base, ink: fg, by: 0.22)
    }

    public subscript(role: ToneRole) -> ColorValue {
        switch role {
        case .base: base
        case .bg: bg
        case .fg: fg
        case .text: text
        }
    }

    /// Step a fill AWAY from the ink that sits on it, so hover and pressed can only ever
    /// make the label MORE legible.
    ///
    /// The web Button always mixes toward black (`color-mix(in oklab, base 86%, #000)`).
    /// That is right for light themes (white ink) but in dark themes the fill is bright and
    /// the ink is dark, so darkening walks toward the ink — pressed `danger` drops to 3.7:1.
    /// Same 14% / 22% steps, direction chosen by the ink.
    static func steppedAwayFromInk(_ fill: ColorValue, ink: ColorValue, by fraction: Double)
        -> ColorValue
    {
        fill.mixed(with: ink.luminance < fill.luminance ? .white : .black, by: fraction)
    }
}

/// The `base / bg / fg` triad the CSS defines for each status hue.
public struct StatusColors: Sendable, Hashable {
    public var base: ColorValue
    public var bg: ColorValue
    public var fg: ColorValue

    public init(base: ColorValue, bg: ColorValue, fg: ColorValue) {
        self.base = base
        self.bg = bg
        self.fg = fg
    }

    public init(_ base: UInt32, bg: UInt32, fg: UInt32) {
        self.init(base: ColorValue(base), bg: ColorValue(bg), fg: ColorValue(fg))
    }
}

/// The five status hues of one theme.
public struct StatusPalette: Sendable, Hashable {
    public var success: StatusColors
    public var info: StatusColors
    public var warning: StatusColors
    public var danger: StatusColors
    public var neutral: StatusColors
}
