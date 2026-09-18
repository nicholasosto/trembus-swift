import AppKit
import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

// Rendering in every theme and the contract are already covered for Textarea by RenderTests
// and ContractTests. This file is for its OWN LOGIC. What it does in a live window — Return, Tab,
// growing — is in TextareaLiveTests.

@Suite("Textarea")
struct TextareaTests {
    @Test func aTextareaIsNeverASingleLine() {
        // The Form: "several lines tall even when it is empty", and one line of text is an Input.
        #expect(Textarea.usable(0...0) == 2...2)
        #expect(Textarea.usable(1...1) == 2...2)
        #expect(Textarea.usable(-3...5) == 2...5)
        #expect(Textarea.usable(Int.max...Int.max) == 100...Int.max, "the blank lines that hold it open are real text")
        #expect(Textarea.usable(4...10) == 4...10, "a sensible range is left alone")
    }

    @Test func theBlankLinesThatHoldTheHeightOpenAreNeverTrulyEmpty() {
        let lines = Textarea.blankLines(4).split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 4)
        #expect(lines.allSatisfy { !$0.isEmpty }, "an empty line may not be measured at all")
        #expect(Textarea.blankLines(0) == " ", "never nothing: the box would collapse")
    }

    @Test func aTrailingNewlineStillCountsAsALine() {
        // The caret sits on that empty last line, so the box must make room for it.
        let measured = Textarea.sizingText("one\n")
        #expect(measured.split(separator: "\n", omittingEmptySubsequences: false).last == " ")
    }

    @Test func itsTextStartsWhereAnInputsTextStarts() {
        for step in [ControlMetrics.Step.sm, .md, .lg] {
            #expect(ControlMetrics.textarea(step).paddingX == ControlMetrics.input(step).paddingX)
            #expect(ControlMetrics.textarea(step).type == ControlMetrics.input(step).type)
            #expect(
                ControlMetrics.textarea(step).paddingX >= Textarea.nativeTextInset,
                "the native inset is subtracted from the padding; it cannot be the larger one")
        }
    }

    @Test func aPlaceholderFollowsTheNativeTextNotTheEnvironment() {
        // `.leading` is NATURAL alignment in AppKit: it follows the app, not SwiftUI's layoutDirection.
        typealias T = FieldText
        #expect(T.placeholderAlignment(.leading, layoutDirection: .leftToRight, appIsRTL: false) == .leading)
        #expect(T.placeholderAlignment(.leading, layoutDirection: .rightToLeft, appIsRTL: false) == .trailing)
        #expect(T.placeholderAlignment(.leading, layoutDirection: .rightToLeft, appIsRTL: true) == .leading)
        #expect(T.placeholderAlignment(.leading, layoutDirection: .leftToRight, appIsRTL: true) == .trailing)
        #expect(T.placeholderAlignment(.center, layoutDirection: .rightToLeft, appIsRTL: false) == .center)
        #expect(T.placeholderAlignment(.trailing, layoutDirection: .rightToLeft, appIsRTL: false) == .trailing)
    }

    @Test func onlyClassicScrollBarsTakeWidthFromTheText() {
        #expect(Textarea.scrollBarGutter(for: .overlay) == 0, "overlay bars float over the text")
        #expect(
            Textarea.scrollBarGutter(for: .legacy) > 10,
            "classic bars are given their width even with nothing to scroll")
    }
}
