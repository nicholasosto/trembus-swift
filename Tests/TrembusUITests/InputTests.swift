import AppKit
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

// Rendering in every theme and the contract are already covered for Input by RenderTests
// and ContractTests. This file is for its OWN LOGIC, which lives in `FieldStatus`.

@Suite("Input")
struct InputTests {
    @Test func blankErrorsCountAsValid() {
        // Validators commonly return "" for "fine" — that must not paint an empty red line.
        #expect(!FieldStatus(error: nil).isInvalid)
        #expect(!FieldStatus(error: "").isInvalid)
        #expect(!FieldStatus(error: "   \n\t ").isInvalid)
        #expect(FieldStatus(error: "Required").isInvalid)
    }

    @Test func errorMessagesAreTrimmed() {
        #expect(FieldStatus(error: "  Required \n").error == "Required")
        #expect(FieldStatus(error: " ").error == nil)
    }

    @Test func invalidOutranksFocused() {
        // A field you are typing in is still wrong until it isn't.
        let valid = FieldStatus(error: nil)
        let invalid = FieldStatus(error: "Nope")
        #expect(valid.edge(isFocused: false) == .rest)
        #expect(valid.edge(isFocused: true) == .focused)
        #expect(invalid.edge(isFocused: false) == .invalid)
        #expect(invalid.edge(isFocused: true) == .invalid)
    }

    @Test func theHintReadsHelperThenError() {
        #expect(FieldStatus(error: nil).accessibilityHint(description: nil).isEmpty)
        #expect(FieldStatus(error: nil).accessibilityHint(description: "We never share it") == "We never share it")
        #expect(FieldStatus(error: "Required").accessibilityHint(description: nil) == "Required")
        #expect(
            FieldStatus(error: "Required").accessibilityHint(description: "We never share it")
                == "We never share it. Required")
        // Blank helper text must not leave a stray separator behind.
        #expect(FieldStatus(error: "Required").accessibilityHint(description: "  ") == "Required")
        // The hand-drawn placeholder is spoken first, while there is one.
        #expect(
            FieldStatus(error: nil).accessibilityHint(description: "We never share it", placeholder: "you@example.com")
                == "you@example.com. We never share it")
        #expect(FieldStatus(error: nil).accessibilityHint(description: nil, placeholder: " ").isEmpty)
    }

    @Test func aRequiredFieldSaysSoOutLoud() {
        // The visible asterisk is decoration and is hidden from assistive tech — without this,
        // "required" would be a fact only sighted users get.
        #expect(FieldText.accessibleName(label: "Email", prompt: "", isRequired: true) == "Email, required")
        #expect(FieldText.accessibleName(label: "Email", prompt: "", isRequired: false) == "Email")
    }

    @Test func aFieldIsNeverNameless() {
        // A blank label falls back to the prompt rather than leaving VoiceOver with "text field".
        #expect(FieldText.name(label: "", prompt: "Search components") == "Search components")
        #expect(FieldText.name(label: "  ", prompt: " Filter… ") == "Filter…")
        #expect(FieldText.name(label: "Email", prompt: "you@example.com") == "Email")
        // Nothing to say at all: stay empty rather than announce ", required" on its own.
        #expect(FieldText.accessibleName(label: "", prompt: "", isRequired: true).isEmpty)
    }

    @Test func thePlaceholderIsOnlySpokenWhenItAddsSomething() {
        #expect(FieldText.placeholderAddsInformation("you@example.com", toName: "Email"))
        // Same words, different dressing — reading both is just noise.
        #expect(!FieldText.placeholderAddsInformation("Filter…", toName: "Filter"))
        #expect(!FieldText.placeholderAddsInformation("filter...", toName: "Filter"))
        #expect(!FieldText.placeholderAddsInformation("Search:", toName: "search"))
        #expect(!FieldText.placeholderAddsInformation("  ", toName: "Email"))
        #expect(!FieldText.placeholderAddsInformation("", toName: "Email"))
    }

    @Test func everyAdornmentSpellingCompiles() {
        // A compile-time test. Trailing-only used to fail with "missing argument for parameter 'leading'",
        // while the web version's `endSlot` works alone. The single trailing closure must still mean LEADING.
        let text = Binding.constant("")
        _ = Input("Plain", text: text)
        _ = Input("Leading", text: text) { Image(systemName: "magnifyingglass") }
        _ = Input("Leading, labelled", text: text, leading: { Image(systemName: "magnifyingglass") })
        _ = Input("Trailing", text: text, trailing: { Text("kg") })
        _ = Input("Both", text: text, leading: { Image(systemName: "dollarsign") }, trailing: { Text("USD") })
    }

    @Test func thePlaceholderIsDrawnInTextFaintNotTheSystemGray() throws {
        // macOS's native text field IGNORES any styling on its `prompt:` (even pure red) and draws
        // a dark gray of its own — close enough to real text that an empty field looks pre-filled.
        // Input therefore draws the placeholder itself. With the label hidden, the placeholder is
        // the darkest thing in the picture, so its darkest pixel tells us which one we got.
        //
        // Measured, light theme, darkest pixel as gray (glyphs are thin, so antialiasing keeps even
        // "solid" text lighter than its nominal color):
        //      ours (textFaint)   0.51        ← want
        //      system placeholder 0.32        ← the bug
        //      no placeholder     ~0.8        ← only the border is left
        // The bounds sit midway between neighbours, so rendering drift on another machine has room.
        let view = Input("Email", text: .constant(""), prompt: "you@example.com")
            .labelsHidden().frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
        let bitmap = try #require(NSBitmapImageRep(data: try Snapshotter.png(of: view, scale: 2).png))
        var darkest = 1.0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                let white = Double(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1)
                darkest = min(darkest, white)
            }
        }
        #expect(darkest > 0.41, "darkest pixel is \(darkest) — that is the system placeholder gray, not textFaint")
        #expect(darkest < 0.66, "darkest pixel is \(darkest) — no placeholder was drawn at all")
    }

    @Test func theNativeFieldNeverPaintsItsTitleAsAPlaceholder() throws {
        // With no prompt, a macOS text field falls back to painting its TITLE as a placeholder. Input
        // draws its own, so a titled native field would stack "Email" on top of "you@example.com".
        // No prompt here, so the field must be visually empty: only the light border remains.
        let view = Input("Email", text: .constant(""))
            .labelsHidden().frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
        let bitmap = try #require(NSBitmapImageRep(data: try Snapshotter.png(of: view, scale: 2).png))
        var darkest = 1.0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                let white = Double(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1)
                darkest = min(darkest, white)
            }
        }
        #expect(
            darkest > 0.66, "darkest pixel is \(darkest) — something was painted inside an empty, prompt-less field")
    }

    @Test func aFieldIsExactlyAsTallAsAButton() {
        // The promise behind the Sizes specimen: a field next to a button lines up, at every size.
        for step in [ControlMetrics.Step.sm, .md, .lg] {
            #expect(ControlMetrics.input(step).height == ControlMetrics.button(step).height)
        }
    }
}
