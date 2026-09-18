import AppKit
import Combine
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

/// These need a real (never shown) window, because focus and the field editor only exist inside one.
extension LiveWindowTests {
    @Suite("Input — live regressions")
    struct InputLiveTests {
        final class Box: ObservableObject {
            @Published var text = ""
            @Published var isSecure = false
        }

        struct Harness: View {
            @ObservedObject var box: Box
            var body: some View {
                Input("Email", text: $box.text, prompt: "you@example.com", isSecure: box.isSecure)
                    .labelsHidden().frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
            }
        }

        @Test func thePlaceholderStepsAsideWhileAnInputMethodComposes() throws {
            let box = Box()
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let field = try #require(
                LiveWindowTests.find(NSTextField.self, in: host), "no native text field was found inside Input")
            window.makeFirstResponder(field)
            LiveWindowTests.settle()
            let editor = try #require(window.firstResponder as? NSTextView, "the field never took focus")

            // Exactly what an input method does: marked text goes into the field editor; `text` stays "".
            editor.setMarkedText(
                "に", selectedRange: NSRange(location: 1, length: 0),
                replacementRange: NSRange(location: NSNotFound, length: 0))
            LiveWindowTests.settle()
            #expect(box.text.isEmpty, "precondition: SwiftUI holds the binding back until the composition commits")

            // "に" ends near x = 40pt; the placeholder "you@example.com" runs on to ~130pt. Anything dark out there is
            // the placeholder showing through the composition.
            let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            let scale = CGFloat(rep.pixelsWide) / host.bounds.width
            var darkest = 1.0
            for x in Int(70 * scale)..<Int(200 * scale) {
                for y in Int(20 * scale)..<Int(34 * scale) {
                    darkest = min(
                        darkest, Double(rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1))
                }
            }
            #expect(darkest > 0.7, "the placeholder is still painted under the composing text (darkest \(darkest))")
        }

        @Test func revealingAPasswordKeepsTheFieldFocused() async throws {
            let box = Box()
            box.text = "hunter2"
            box.isSecure = true
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let field = try #require(
                LiveWindowTests.find(NSTextField.self, in: host), "no native text field was found inside Input")
            window.makeFirstResponder(field)
            LiveWindowTests.settle()
            #expect(window.firstResponder is NSTextView, "precondition: the field took focus")

            box.isSecure = false  // the classic "show password" eye button
            // A main-actor test IS a main-queue job: anything the component defers to the main queue can only
            // run once this function suspends. So await first, then let the run loop lay the new field out.
            for _ in 0..<3 {
                LiveWindowTests.settle(0.15)
                try await Task.sleep(for: .milliseconds(100))
            }
            LiveWindowTests.settle(0.15)
            #expect(window.firstResponder is NSTextView, "toggling isSecure dropped keyboard focus")
            #expect(box.text == "hunter2")
            // Handing focus back makes AppKit select ALL — so the very next keystroke would replace the
            // whole password. The caret must end up after the last character, with nothing selected.
            let editor = try #require(window.firstResponder as? NSTextView)
            #expect(
                editor.selectedRange() == NSRange(location: 7, length: 0),
                "after revealing, the selection is \(editor.selectedRange()) — the next keystroke would replace the password"
            )
        }

        @Test func clickingTheBoxPaddingPlacesTheCaretInsteadOfSelectingEverything() async throws {
            // The native field is only ~17pt tall inside a 30pt box. A click in the band above or below it is
            // handled by Input, which focuses the field — and AppKit answers a programmatic focus with
            // select-all. Someone who clicks "in the box" and types then silently loses what was there.
            let box = Box()
            box.text = "ada@example.com"
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let field = try #require(LiveWindowTests.find(NSTextField.self, in: host))
            let frame = field.convert(field.bounds, to: nil)
            // 3pt above the native field: inside Input's box, outside the native view.
            LiveWindowTests.click(window, at: NSPoint(x: frame.midX, y: frame.maxY + 3))
            for _ in 0..<3 {
                LiveWindowTests.settle(0.15)
                try await Task.sleep(for: .milliseconds(100))
            }
            let editor = try #require(
                window.firstResponder as? NSTextView, "a click on the box padding did not focus the field")
            #expect(
                editor.selectedRange() == NSRange(location: 15, length: 0),
                "after a click on the padding the selection is \(editor.selectedRange()) — typing would replace everything"
            )
        }
    }
}
