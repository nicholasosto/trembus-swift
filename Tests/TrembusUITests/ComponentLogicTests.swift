import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

@Suite("InteractionState")
struct InteractionStateTests {
    @Test func phasePrecedenceIsDisabledThenPressedThenHover() {
        #expect(InteractionState.rest.phase == .rest)
        #expect(InteractionState.hovered.phase == .hover)
        #expect(InteractionState.pressed.phase == .pressed)  // pressed implies hovered
        #expect(InteractionState(isHovered: true, isPressed: true, isEnabled: false).phase == .disabled)
    }

    @Test func focusIsIndependentOfThePointerPhase() {
        #expect(InteractionState.focused.phase == .rest)
        #expect(InteractionState(isHovered: true, isFocused: true).phase == .hover)
    }
}

@Suite("Meter")
struct MeterTests {
    @Test func fractionIsClampedToTheRange() {
        #expect(Meter(value: 0.5).fraction == 0.5)
        #expect(Meter(value: -3).fraction == 0)
        #expect(Meter(value: 7).fraction == 1)
        #expect(Meter(value: 42, in: 0...60).fraction == 0.7)
        #expect(Meter(value: 15, in: 10...20).fraction == 0.5)
    }

    @Test func degenerateInputReadsAsEmptyNotACrash() {
        #expect(Meter(value: 5, in: 5...5).fraction == 0)  // zero-width range
        #expect(Meter(value: .nan).fraction == 0)
        #expect(Meter(value: .infinity).fraction == 0)
    }

    @Test func levelsPickTheToneFromTheValue() {
        let rule = Meter.ToneRule.levels(dangerBelow: 0.1, warningBelow: 0.25)
        #expect(rule.tone(for: 0.05) == .danger)
        #expect(rule.tone(for: 0.1) == .warning)  // boundaries belong to the better zone
        #expect(rule.tone(for: 0.2) == .warning)
        #expect(rule.tone(for: 0.25) == .success)
        #expect(rule.tone(for: 1) == .success)
        #expect(Meter.ToneRule.fixed(.info).tone(for: 0) == .info)
    }
}

@Suite("ControlMetrics")
struct ControlMetricsTests {
    @Test func everyControlSizeMapsToAStep() {
        #expect(ControlMetrics.Step(.mini) == .sm)
        #expect(ControlMetrics.Step(.small) == .sm)
        #expect(ControlMetrics.Step(.regular) == .md)
        #expect(ControlMetrics.Step(.large) == .lg)
        #expect(ControlMetrics.Step(.extraLarge) == .lg)
    }

    @Test func sizesGrowWithTheStep() {
        let steps: [ControlMetrics.Step] = [.sm, .md, .lg]
        let buttons = steps.map { ControlMetrics.button($0).height }
        let switches = steps.map { ControlMetrics.switch($0).height }
        #expect(buttons == buttons.sorted() && Set(buttons).count == 3)
        #expect(switches == switches.sorted() && Set(switches).count == 3)
    }

    @Test func theSwitchThumbFitsInsideItsTrack() {
        for step in [ControlMetrics.Step.sm, .md, .lg] {
            let metrics = ControlMetrics.switch(step)
            #expect(metrics.thumb > 0)
            // Even fully stretched (+25%) the thumb must leave room to travel.
            #expect(metrics.thumb * 1.25 + metrics.inset * 2 < metrics.width)
        }
    }
}
