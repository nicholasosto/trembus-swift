import SwiftUI
import Testing

@testable import TrembusTokens

@Suite("Theme")
struct ThemeTests {
    @Test func automaticFollowsTheColorScheme() {
        #expect(ThemeChoice.automatic().resolve(for: .light) == .light)
        #expect(ThemeChoice.automatic().resolve(for: .dark) == .dark)
        #expect(ThemeChoice.automatic(dark: .reliquary).resolve(for: .dark) == .reliquary)
    }

    @Test func fixedIgnoresTheColorScheme() {
        #expect(ThemeChoice.fixed(.reliquary).resolve(for: .light) == .reliquary)
    }

    @Test func unsetEnvironmentResolvesToTheSystemAppearance() {
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        #expect(environment.theme == .dark)
        environment.colorScheme = .light
        #expect(environment.theme == .light)
    }

    @Test func everyThemeDeclaresASchemeThatMatchesItsPage() {
        for theme in Theme.all {
            let pageIsDark = theme.color.bg.luminance < 0.5
            #expect((theme.scheme == .dark) == pageIsDark, "\(theme.name)")
        }
    }

    @Test func themeNamesAreUnique() {
        #expect(Set(Theme.all.map(\.name)).count == Theme.all.count)
    }
}

@Suite("Tokens")
struct TokenTests {
    @Test func cssNamesMatchTheWebTokens() {
        #expect(ColorToken.bg.cssName == "--tcl-bg")
        #expect(ColorToken.surfaceRaised.cssName == "--tcl-surface-raised")
        #expect(ColorToken.accentFg.cssName == "--tcl-accent-fg")
        #expect(ColorToken.focusRing.cssName == "--tcl-focus-ring")
    }

    @Test func increasedContrastOnlyEverStepsTowardMoreContrast() {
        for theme in Theme.all {
            for token in ColorToken.allCases where token.increasedContrast != token {
                let page = theme.color.bg
                let before = theme.color[token].contrast(against: page)
                let after = theme.color[token.increasedContrast].contrast(against: page)
                #expect(after >= before, "\(theme.name): \(token.rawValue) → \(token.increasedContrast.rawValue)")
            }
        }
    }

    @Test func toneAsTextFollowsTheLegibilityRule() {
        for theme in Theme.all {
            #expect(theme.tone(.accent).text == theme.color.text)
            #expect(theme.tone(.neutral).text == theme.color.textDim)
            #expect(theme.tone(.danger).text == theme.status.danger.base)
        }
    }

    @Test func scalesMatchTheWebValues() {
        #expect(Space.steps == [0, 2, 4, 8, 12, 16, 24, 32, 48])
        #expect(Radius.allCases.map(\.value) == [0, 4, 5, 10, 9999])
        #expect(TypeScale.allCases.map(\.size) == [11, 12, 14, 16, 20, 28])
        #expect(Motion.Duration.allCases.map(\.seconds) == [0.12, 0.20, 0.32])
    }

    @Test func curvesStartAtZeroAndEndAtOne() {
        for curve in [Motion.easeCalm, Motion.easeExit] {
            #expect(abs(curve.value(at: 0)) < 1e-6)
            #expect(abs(curve.value(at: 1) - 1) < 1e-6)
        }
    }

    @Test func springsSettleOnTheirTarget() {
        for spring in Motion.Springs.allCases {
            let settled = spring.spring.value(target: 1.0, initialVelocity: 0, time: 2)
            #expect(abs(settled - 1) < 0.001, "\(spring.rawValue)")
        }
        // Only `press` is bounce-free: it must never overshoot.
        let peak =
            stride(from: 0.0, through: 1.0, by: 0.005)
            .map { Motion.Springs.press.spring.value(target: 1.0, initialVelocity: 0, time: $0) }
            .max() ?? 0
        #expect(peak <= 1.0001)
    }
}
