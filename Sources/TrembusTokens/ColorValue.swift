import SwiftUI

/// A color you can do math on. sRGB, components 0...1.
///
/// Tokens are stored as `ColorValue` (not `Color`) so the same value can be painted,
/// mixed for hover/pressed states, and contrast-checked in tests.
public struct ColorValue: Sendable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `ColorValue(0xD4AF37)` — the same hex the CSS tokens use.
    public init(_ hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha)
    }

    public static let black = ColorValue(0x000000)
    public static let white = ColorValue(0xFFFFFF)
    public static let clear = ColorValue(0x000000, alpha: 0)

    /// The paintable SwiftUI color.
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }

    /// `#d4af37` (alpha is not encoded).
    public var hex: String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", byte(red), byte(green), byte(blue))
    }

    public func opacity(_ alpha: Double) -> ColorValue {
        var copy = self
        copy.alpha = alpha
        return copy
    }

    /// Alpha-composite this color over an opaque backdrop. Result is opaque.
    ///
    /// Tints are pre-composited so a soft Badge has ONE deterministic backdrop wherever it
    /// lands, instead of a translucent wash that compounds with whatever is behind it.
    public func over(_ backdrop: ColorValue) -> ColorValue {
        ColorValue(
            red: red * alpha + backdrop.red * (1 - alpha),
            green: green * alpha + backdrop.green * (1 - alpha),
            blue: blue * alpha + backdrop.blue * (1 - alpha))
    }

    /// Mix toward `other` in OKLab — matches CSS `color-mix(in oklab, …)`.
    /// `fraction` 0 returns self, 1 returns `other`.
    public func mixed(with other: ColorValue, by fraction: Double) -> ColorValue {
        let t = min(max(fraction, 0), 1)
        let a = OKLab(self)
        let b = OKLab(other)
        let mixed = OKLab(
            l: a.l + (b.l - a.l) * t,
            a: a.a + (b.a - a.a) * t,
            b: a.b + (b.b - a.b) * t)
        return mixed.colorValue(alpha: alpha + (other.alpha - alpha) * t)
    }
}

// MARK: - Contrast (WCAG 2.x)

extension ColorValue {
    /// WCAG relative luminance, 0 (black) ... 1 (white). Ignores alpha — composite first.
    public var luminance: Double {
        0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue)
    }

    /// WCAG contrast ratio, 1...21. Text needs 4.5, large text and UI edges need 3.
    public func contrast(against other: ColorValue) -> Double {
        let lighter = max(luminance, other.luminance)
        let darker = min(luminance, other.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func linear(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    static func gamma(_ channel: Double) -> Double {
        let c = min(max(channel, 0), 1)
        return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
    }
}

// MARK: - OKLab

/// Björn Ottosson's OKLab — a perceptual space where mixing looks even.
struct OKLab {
    var l: Double
    var a: Double
    var b: Double

    init(l: Double, a: Double, b: Double) {
        self.l = l
        self.a = a
        self.b = b
    }

    init(_ value: ColorValue) {
        let r = ColorValue.linear(value.red)
        let g = ColorValue.linear(value.green)
        let bl = ColorValue.linear(value.blue)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl)
        self.l = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        self.a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        self.b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    }

    func colorValue(alpha: Double) -> ColorValue {
        let l3 = pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
        let m3 = pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
        let s3 = pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)
        return ColorValue(
            red: ColorValue.gamma(4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3),
            green: ColorValue.gamma(-1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3),
            blue: ColorValue.gamma(-0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3),
            alpha: alpha)
    }
}
