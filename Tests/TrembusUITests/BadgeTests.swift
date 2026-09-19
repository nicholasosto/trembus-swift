import Testing

@testable import TrembusTokens
@testable import TrembusUI

// Badge is nearly all presentation, but one piece of logic can break: the tone → glyph map that
// carries meaning when the user has Differentiate Without Color on. Tone must never be the only
// signal, so every tone needs a real, distinct symbol.

@Suite("Badge")
struct BadgeTests {
    @Test func everyToneMapsToARealDistinctGlyph() {
        let names = Tone.allCases.map(\.symbolName)
        #expect(names.allSatisfy { !$0.isEmpty }, "a tone with no glyph would leave color as the only signal")
        #expect(Set(names).count == Tone.allCases.count, "two tones sharing a glyph would be indistinguishable")
    }

    @Test func toneGlyphsAreTheOnesWeChose() {
        #expect(Tone.accent.symbolName == "star.fill")
        #expect(Tone.info.symbolName == "info")
        #expect(Tone.success.symbolName == "checkmark")
        #expect(Tone.warning.symbolName == "exclamationmark")
        #expect(Tone.danger.symbolName == "xmark")
        #expect(Tone.neutral.symbolName == "minus")
    }
}
