import AppKit
import Combine
import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

/// What the Form promises about a LIVE field: how tall it is, what Return does, what Tab does.
/// These need a real (never shown) window — see `LiveWindowTests`.
extension LiveWindowTests {
    @Suite("Textarea — live")
    struct TextareaLiveTests {
        final class Box: ObservableObject {
            @Published var text = ""
            @Published var next = ""
        }

        struct Harness: View {
            @ObservedObject var box: Box
            var lines = 3...6
            var body: some View {
                VStack {
                    Textarea("Notes", text: $box.text, prompt: "Write here", lines: lines).labelsHidden()
                    Input("Next", text: $box.next).labelsHidden()
                }
                .frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
            }
        }

        private func height(of text: String, lines: ClosedRange<Int>) -> CGFloat {
            NSHostingView(
                rootView: Textarea("Notes", text: .constant(text), lines: lines).labelsHidden().frame(width: 220)
            )
            .fittingSize.height
        }

        @Test func theFieldIsSeveralLinesTallEvenWhenEmptyAndStopsGrowingAtTheMost() {
            let twoLines = height(of: "", lines: 2...2)
            let empty = height(of: "", lines: 3...6)
            let four = height(of: "1\n2\n3\n4", lines: 3...6)
            let six = height(of: "1\n2\n3\n4\n5\n6", lines: 3...6)
            let twenty = height(of: (1...20).map(String.init).joined(separator: "\n"), lines: 3...6)
            let line = (six - empty) / 3

            #expect(line > 10, "precondition: a line of text has a real height (got \(line))")
            #expect(
                abs((empty - twoLines) - line) < 1, "empty 3-line field is \(empty)pt; a 2-line field is \(twoLines)pt")
            #expect(abs((four - empty) - line) < 1, "a fourth line should add one line of height")
            #expect(twenty == six, "past the most lines it must scroll, not grow (\(twenty) vs \(six))")
            #expect(
                height(of: "1\n2\n3\n", lines: 3...6) == four, "a trailing newline is a real line: the caret sits on it"
            )
        }

        @Test func longTextWrapsInsteadOfWideningTheField() {
            let long = String(repeating: "wrap me around ", count: 12)
            let host = NSHostingView(
                rootView: Textarea("Notes", text: .constant(long), lines: 2...10).labelsHidden().frame(width: 220))
            #expect(host.fittingSize.width == 220)
            #expect(
                host.fittingSize.height > height(of: "one line", lines: 2...10) + 10,
                "the text did not wrap onto more lines")
        }

        @Test func theNativeTextViewInsetsAreWhatTheLayoutAssumes() throws {
            let (window, host) = LiveWindowTests.mount(Harness(box: Box()))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(
                LiveWindowTests.find(NSTextView.self, in: host), "no native text view was found inside Textarea")
            #expect(view.textContainer?.lineFragmentPadding == Textarea.nativeTextInset)
            #expect(view.textContainerInset == .zero, "an inset here would push the text off the placeholder")
            #expect(!view.isRichText, "the Form: it holds plain text only — a paste must not bring its styling along")
        }

        @Test func theBoxIsExactlyAsTallAsTheNativeTextInsideIt() throws {
            // The height comes from invisible SwiftUI text; the words are drawn by a native text view. They only
            // agree if both wrap at the same width — and with classic (always visible) scroll bars the native
            // view gives 17pt of its width away. Many words of mixed length make the lost width show up as lost lines.
            let box = Box()
            box.text = (1...150).map { String(repeating: "m", count: $0 % 7 + 1) }.joined(separator: " ")
            let (window, host) = LiveWindowTests.mount(Harness(box: box, lines: 2...100))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            let container = try #require(view.textContainer)
            let layout = try #require(view.layoutManager)
            layout.ensureLayout(for: container)
            let needed = layout.usedRect(for: container).height
            let given = try #require(view.enclosingScrollView).contentSize.height
            #expect(
                abs(needed - given) < 2,
                "the native text needs \(needed)pt but the box gives it \(given)pt (scroll bars: \(NSScroller.preferredScrollerStyle == .legacy ? "classic" : "overlay"))"
            )
        }

        @Test func theBoxGrowsWhileAnInputMethodComposes() throws {
            // The composing text lives in the text view; the binding stays "" until it commits. A box sized
            // from the binding alone would sit still through a long composition, then jump when it lands.
            let box = Box()
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            window.makeFirstResponder(view)
            LiveWindowTests.settle()
            let before = host.fittingSize.height

            let composing = String(repeating: "にほんご ", count: 30)  // wraps onto 5+ lines at this width
            view.setMarkedText(
                composing, selectedRange: NSRange(location: (composing as NSString).length, length: 0),
                replacementRange: NSRange(location: NSNotFound, length: 0))
            LiveWindowTests.settle()
            #expect(box.text.isEmpty, "precondition: SwiftUI holds the binding back until the composition commits")
            #expect(
                host.fittingSize.height > before + 20,
                "the box stayed \(host.fittingSize.height)pt tall (was \(before)pt) under 5+ lines of composing text")
        }

        @Test func clickingTheBoxPaddingFocusesTheTextWithoutSelectingIt() async throws {
            let box = Box()
            box.text = "one two three"
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            let frame = try #require(view.enclosingScrollView).convert(view.enclosingScrollView!.bounds, to: nil)
            // 3pt above the native view: inside Textarea's box, outside the text view.
            LiveWindowTests.click(window, at: NSPoint(x: frame.midX, y: frame.maxY + 3))
            for _ in 0..<3 {
                LiveWindowTests.settle(0.15)
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(window.firstResponder === view, "a click on the box padding did not focus the text")
            #expect(view.selectedRange().length == 0, "the click selected text: the next keystroke would replace it")
        }

        @Test func returnStartsANewLine() throws {
            let box = Box()
            box.text = "one"
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            window.makeFirstResponder(view)
            view.setSelectedRange(NSRange(location: 3, length: 0))
            LiveWindowTests.settle()

            LiveWindowTests.press(window, "\r", keyCode: 36)
            LiveWindowTests.settle()
            #expect(box.text == "one\n", "after Return the text is \(box.text.debugDescription)")
            #expect(window.firstResponder === view, "Return must not move focus")
        }

        @Test func tabLeavesTheFieldAndNeverTypesATab() async throws {
            let box = Box()
            box.text = "one"
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            window.makeFirstResponder(view)
            LiveWindowTests.settle()
            #expect(window.firstResponder === view, "precondition: the text view took focus")

            LiveWindowTests.press(window, "\t", keyCode: 48)
            // The move is deferred to the next main-queue turn, which only runs once this test suspends.
            for _ in 0..<3 {
                LiveWindowTests.settle(0.15)
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(box.text == "one", "Tab typed into the field: \(box.text.debugDescription)")
            #expect(window.firstResponder !== view, "Tab did not leave the textarea")
            let editor = try #require(window.firstResponder as? NSTextView, "Tab did not land in the next field")
            #expect(editor.isFieldEditor, "focus went to \(editor), not to the Input after the textarea")
        }

        @Test func shiftTabLeavesTooAndNeverTypesATab() async throws {
            let box = Box()
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            window.makeFirstResponder(view)
            LiveWindowTests.settle()

            LiveWindowTests.press(window, "\u{19}", keyCode: 48, shift: true)  // what AppKit sends for Shift-Tab
            for _ in 0..<3 {
                LiveWindowTests.settle(0.15)
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(box.text.isEmpty, "Shift-Tab typed into the field: \(box.text.debugDescription)")
            #expect(window.firstResponder !== view, "Shift-Tab did not leave the textarea")
        }

        @Test func thePlaceholderStepsAsideWhileAnInputMethodComposes() throws {
            let box = Box()
            let (window, host) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let view = try #require(LiveWindowTests.find(NSTextView.self, in: host))
            window.makeFirstResponder(view)
            LiveWindowTests.settle()

            func darkestInk() throws -> Double {
                // "に" ends near x = 40pt; the placeholder "Write here" runs on to ~90pt. Anything dark out
                // there, on the first line, is the placeholder.
                let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: rep)
                let scale = CGFloat(rep.pixelsWide) / host.bounds.width
                var darkest = 1.0
                for x in Int(50 * scale)..<Int(120 * scale) {
                    for y in Int(20 * scale)..<Int(38 * scale) {
                        darkest = min(
                            darkest, Double(rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1))
                    }
                }
                return darkest
            }
            #expect(try darkestInk() < 0.7, "precondition: the placeholder is drawn where this test looks")

            // Exactly what an input method does: marked text goes into the text view; `text` stays "".
            view.setMarkedText(
                "に", selectedRange: NSRange(location: 1, length: 0),
                replacementRange: NSRange(location: NSNotFound, length: 0))
            LiveWindowTests.settle()
            #expect(box.text.isEmpty, "precondition: SwiftUI holds the binding back until the composition commits")
            let darkest = try darkestInk()
            #expect(darkest > 0.7, "the placeholder is still painted under the composing text (darkest \(darkest))")
        }
    }
}
