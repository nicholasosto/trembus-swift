import SwiftUI

// The three shipped themes. VALUES are copied hex-for-hex from
//   Trembus-Component-Library/packages/tokens/src/css/tokens.{light,dark,reliquary}.css
// That CSS is the source of truth — when it changes, re-sync here. The AA comments
// explaining WHY a value is what it is live there, not here.

extension Theme {
    /// claude.ai-clean: warm white, near-black text, restrained gold accent.
    public static let light = Theme(
        name: "light",
        scheme: .light,
        color: Palette(
            bg: ColorValue(0xFFFFFF),
            surface: ColorValue(0xF7F7F6),
            surfaceRaised: ColorValue(0xFFFFFF),
            surfaceSunken: ColorValue(0xEFEEEA),
            surfaceHover: ColorValue(0xF0EFEC),
            overlay: ColorValue(red: 20 / 255, green: 20 / 255, blue: 18 / 255, alpha: 0.45),
            border: ColorValue(0xE6E4DF),
            borderSoft: ColorValue(0xEFEEEA),
            borderStrong: ColorValue(0xD4D1C9),
            text: ColorValue(0x1A1A18),
            textDim: ColorValue(0x6B6B66),
            textFaint: ColorValue(0x6F6F69),
            accent: ColorValue(0xD4AF37),
            accentHover: ColorValue(0xC2A030),
            accentActive: ColorValue(0xAB8C24),
            accentFg: ColorValue(0x1A1A18),
            focusRing: ColorValue(0x946F1C)),
        status: StatusPalette(
            success: StatusColors(0x1A7F37, bg: 0xE8F5EC, fg: 0xFFFFFF),
            info: StatusColors(0x0969DA, bg: 0xDDF4FF, fg: 0xFFFFFF),
            warning: StatusColors(0x9A6700, bg: 0xFFF8E6, fg: 0xFFFFFF),
            danger: StatusColors(0xCF222E, bg: 0xFFEBE9, fg: 0xFFFFFF),
            neutral: StatusColors(0x6B6B66, bg: 0xF0EFEC, fg: 0xFFFFFF)),
        elevation: ElevationScale(
            e1: ElevationStyle(shadows: [
                ShadowLayer(.ink(0.06), blur: 2, y: 1), ShadowLayer(.ink(0.10), blur: 3, y: 1),
            ]),
            e2: ElevationStyle(shadows: [
                ShadowLayer(.ink(0.10), blur: 12, y: 4), ShadowLayer(.ink(0.06), blur: 4, y: 2),
            ]),
            e3: ElevationStyle(shadows: [
                ShadowLayer(.ink(0.16), blur: 32, y: 12), ShadowLayer(.ink(0.08), blur: 8, y: 4),
            ])))

    /// The Trembus Visual Grammar palette: blue-black chrome, gold accent, bright status hues.
    public static let dark = Theme(
        name: "dark",
        scheme: .dark,
        color: Palette(
            bg: ColorValue(0x0A0D12),
            surface: ColorValue(0x1C2128),
            surfaceRaised: ColorValue(0x232A32),
            surfaceSunken: ColorValue(0x14181E),
            surfaceHover: ColorValue(0x232A32),
            overlay: ColorValue(red: 5 / 255, green: 7 / 255, blue: 10 / 255, alpha: 0.66),
            border: ColorValue(0x2A3038),
            borderSoft: ColorValue(0x1F242C),
            borderStrong: ColorValue(0x3A4350),
            text: ColorValue(0xE6EDF3),
            textDim: ColorValue(0xA6AFBA),
            textFaint: ColorValue(0x8B94A4),
            accent: ColorValue(0xD4AF37),
            accentHover: ColorValue(0xE2C456),
            accentActive: ColorValue(0xC5A230),
            accentFg: ColorValue(0x0A0D12),
            focusRing: ColorValue(0xD4AF37)),
        status: StatusPalette(
            success: StatusColors(0x88FF44, bg: 0x293C2B, fg: 0x0A0D12),
            info: StatusColors(0x44DDFF, bg: 0x213842, fg: 0x0A0D12),
            warning: StatusColors(0xFF8855, bg: 0x372D2D, fg: 0x0A0D12),
            danger: StatusColors(0xFF6464, bg: 0x37292F, fg: 0x0A0D12),
            neutral: StatusColors(0x8B949E, bg: 0x292F36, fg: 0x0A0D12)),
        elevation: ElevationScale(
            e1: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.40), blur: 2, y: 1)], hairline: .glint(0.02)),
            e2: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.50), blur: 24, y: 8)], hairline: .glint(0.03)),
            e3: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.60), blur: 48, y: 16)], hairline: .glint(0.04))))

    /// Blood-dark sibling of `dark`: warm near-black chrome, the order's red as accent.
    /// Accent and danger are different reds BY ROLE (brand vs. intent).
    public static let reliquary = Theme(
        name: "reliquary",
        scheme: .dark,
        color: Palette(
            bg: ColorValue(0x0C0708),
            surface: ColorValue(0x1A1012),
            surfaceRaised: ColorValue(0x241619),
            surfaceSunken: ColorValue(0x120A0C),
            surfaceHover: ColorValue(0x241619),
            overlay: ColorValue(red: 6 / 255, green: 3 / 255, blue: 4 / 255, alpha: 0.7),
            border: ColorValue(0x3A2226),
            borderSoft: ColorValue(0x24171A),
            borderStrong: ColorValue(0x5A3036),
            text: ColorValue(0xF0E6E6),
            textDim: ColorValue(0xB8A3A3),
            textFaint: ColorValue(0x958083),
            accent: ColorValue(0xB4242C),
            accentHover: ColorValue(0xC92D35),
            accentActive: ColorValue(0x9A1D24),
            accentFg: ColorValue(0xFDECEC),
            focusRing: ColorValue(0xFF5A5F)),
        status: StatusPalette(
            success: StatusColors(0x88FF44, bg: 0x272D18, fg: 0x0C0708),
            info: StatusColors(0x44DDFF, bg: 0x1F292E, fg: 0x0C0708),
            warning: StatusColors(0xFF8855, bg: 0x351E1A, fg: 0x0C0708),
            danger: StatusColors(0xFF6464, bg: 0x351A1C, fg: 0x0C0708),
            neutral: StatusColors(0xB09A9A, bg: 0x2C2122, fg: 0x0C0708)),
        elevation: ElevationScale(
            e1: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.45), blur: 2, y: 1)], hairline: .glint(0.02)),
            e2: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.55), blur: 24, y: 8)], hairline: .glint(0.03)),
            e3: ElevationStyle(
                shadows: [ShadowLayer(.shade(0.65), blur: 48, y: 16)], hairline: .glint(0.04))))
}

extension ColorValue {
    /// Light-theme shadow ink — `rgba(20, 20, 18, α)`.
    fileprivate static func ink(_ alpha: Double) -> ColorValue {
        ColorValue(red: 20 / 255, green: 20 / 255, blue: 18 / 255, alpha: alpha)
    }

    /// Dark-theme shadow — `rgba(0, 0, 0, α)`.
    fileprivate static func shade(_ alpha: Double) -> ColorValue { ColorValue.black.opacity(alpha) }

    /// Dark-theme hairline — `rgba(255, 255, 255, α)`.
    fileprivate static func glint(_ alpha: Double) -> ColorValue { ColorValue.white.opacity(alpha) }
}
