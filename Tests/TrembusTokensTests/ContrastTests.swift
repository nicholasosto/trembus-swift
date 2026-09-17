import Foundation
import Testing

@testable import TrembusTokens

// The accessibility floor, machine-checked for every theme. The web library tuned these
// values by hand for AA; this proves the Swift copies still clear the same bars — and will
// catch a bad value the moment someone adds a fourth theme.

extension Theme: CustomTestStringConvertible {
    public var testDescription: String { name }
}

@Suite("Contrast — WCAG AA")
struct ContrastTests {
    /// Body text: 4.5:1.
    static let text = 4.5
    /// UI edges and focus indicators: 3:1.
    static let edge = 3.0

    /// Gaps inherited from the web token CSS (the source of truth — not forked here).
    ///
    /// `--tcl-text-faint` (#6f6f69) was tuned for AA on white, but lands at 4.35–4.40:1 on the
    /// two tinted light surfaces — a realistic pairing (placeholder text in a sunken well).
    /// Fix it in `tokens.light.css`, re-sync `Themes.swift`, then delete these entries:
    /// `withKnownIssue` FAILS once the gap is gone, so this list can't quietly go stale.
    static let inheritedGaps: Set<String> = [
        "light/textFaint/surfaceSunken",
        "light/textFaint/surfaceHover",
    ]

    @Test("text tokens are legible on every surface", arguments: Theme.all)
    func textOnSurfaces(theme: Theme) {
        let inks: [ColorToken] = [.text, .textDim, .textFaint]
        let papers: [ColorToken] = [.bg, .surface, .surfaceRaised, .surfaceSunken, .surfaceHover]
        for ink in inks {
            for paper in papers {
                let ratio = theme.color[ink].contrast(against: theme.color[paper])
                let comment: Comment = "\(theme.name): \(ink.rawValue) on \(paper.rawValue) is \(ratio.formatted())"
                if Self.inheritedGaps.contains("\(theme.name)/\(ink.rawValue)/\(paper.rawValue)") {
                    withKnownIssue("inherited from the web tokens") { #expect(ratio >= Self.text, comment) }
                } else {
                    #expect(ratio >= Self.text, comment)
                }
            }
        }
    }

    @Test("ink on a solid tone fill is legible", arguments: Theme.all)
    func inkOnSolidTone(theme: Theme) {
        for tone in Tone.allCases {
            let colors = theme.tone(tone)
            let ratio = colors.fg.contrast(against: colors.base)
            #expect(ratio >= Self.text, "\(theme.name): \(tone.rawValue) fg on base is \(ratio.formatted())")
        }
    }

    @Test("a tone painted as text is legible on its own tint and on the page", arguments: Theme.all)
    func toneAsText(theme: Theme) {
        for tone in Tone.allCases {
            let colors = theme.tone(tone)
            let papers: [(String, ColorValue)] = [
                ("own tint", colors.bg), ("bg", theme.color.bg), ("surface", theme.color.surface),
                ("surfaceRaised", theme.color.surfaceRaised),
            ]
            for (name, paper) in papers {
                let ratio = colors.text.contrast(against: paper)
                #expect(ratio >= Self.text, "\(theme.name): \(tone.rawValue) text on \(name) is \(ratio.formatted())")
            }
        }
    }

    @Test("the focus ring stands out from the page", arguments: Theme.all)
    func focusRing(theme: Theme) {
        for paper in [ColorToken.bg, .surface] {
            let ratio = theme.color.focusRing.contrast(against: theme.color[paper])
            #expect(ratio >= Self.edge, "\(theme.name): focusRing on \(paper.rawValue) is \(ratio.formatted())")
        }
    }

    @Test("hover and pressed fills keep their ink legible", arguments: Theme.all)
    func derivedStates(theme: Theme) {
        for tone in Tone.allCases {
            let colors = theme.tone(tone)
            for (name, fill) in [("hover", colors.hover), ("pressed", colors.pressed)] {
                let ratio = colors.fg.contrast(against: fill)
                #expect(ratio >= Self.text, "\(theme.name): \(tone.rawValue) fg on \(name) is \(ratio.formatted())")
            }
        }
    }
}
