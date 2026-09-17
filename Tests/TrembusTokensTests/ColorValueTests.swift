import Testing

@testable import TrembusTokens

@Suite("ColorValue")
struct ColorValueTests {
    @Test func parsesHex() {
        let gold = ColorValue(0xD4AF37)
        #expect(abs(gold.red - 212.0 / 255) < 1e-9)
        #expect(abs(gold.green - 175.0 / 255) < 1e-9)
        #expect(abs(gold.blue - 55.0 / 255) < 1e-9)
        #expect(gold.alpha == 1)
        #expect(gold.hex == "#d4af37")
    }

    @Test func contrastMatchesWCAGReferencePoints() {
        #expect(abs(ColorValue.black.contrast(against: .white) - 21) < 1e-9)
        #expect(ColorValue.white.contrast(against: .white) == 1)
        // Order must not matter.
        let a = ColorValue(0x1A7F37)
        #expect(a.contrast(against: .white) == ColorValue.white.contrast(against: a))
        // #767676 on white is the canonical "just passes AA" gray: 4.54:1.
        #expect(abs(ColorValue(0x767676).contrast(against: .white) - 4.54) < 0.01)
    }

    @Test func compositesOverABackdrop() {
        let half = ColorValue.black.opacity(0.5).over(.white)
        #expect(abs(half.red - 0.5) < 1e-9)
        #expect(half.alpha == 1)
        // Fully opaque ignores the backdrop; fully clear becomes it.
        #expect(ColorValue(0xD4AF37).over(.black) == ColorValue(0xD4AF37))
        #expect(ColorValue.clear.over(ColorValue(0xD4AF37)) == ColorValue(0xD4AF37))
    }

    @Test func mixingHasExactEndpointsAndDarkensTowardBlack() {
        let gold = ColorValue(0xD4AF37)
        #expect(gold.mixed(with: .black, by: 0).hex == gold.hex)
        #expect(gold.mixed(with: .black, by: 1).hex == "#000000")
        let hover = gold.mixed(with: .black, by: 0.14)
        let pressed = gold.mixed(with: .black, by: 0.22)
        #expect(hover.luminance < gold.luminance)
        #expect(pressed.luminance < hover.luminance)
    }

    @Test func hoverAndPressedStepAwayFromTheInk() {
        // Light: white ink on a dark-ish fill → the fill darkens.
        let light = Theme.light.tone(.danger)
        #expect(light.hover.luminance < light.base.luminance)
        #expect(light.pressed.luminance < light.hover.luminance)
        // Dark: dark ink on a bright fill → the fill LIGHTENS (darkening would walk into the ink).
        let dark = Theme.dark.tone(.danger)
        #expect(dark.hover.luminance > dark.base.luminance)
        #expect(dark.pressed.luminance > dark.hover.luminance)
        // Accent uses the hover/active values authored in the theme, not a derived mix.
        for theme in Theme.all {
            #expect(theme.tone(.accent).hover == theme.color.accentHover)
            #expect(theme.tone(.accent).pressed == theme.color.accentActive)
        }
    }

    @Test func okLabRoundTripsEveryShippedColor() {
        for theme in Theme.all {
            for token in ColorToken.allCases {
                let original = theme.color[token]
                let back = OKLab(original).colorValue(alpha: original.alpha)
                #expect(back.hex == original.hex, "\(theme.name).\(token.rawValue)")
            }
        }
    }
}
