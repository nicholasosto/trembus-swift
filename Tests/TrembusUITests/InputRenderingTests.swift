import AppKit
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

@Suite("Input — rendering regressions")
struct InputRenderingTests {
    /// Leftmost / rightmost column (in points) of anything darker than `threshold` inside the box's text band.
    private func inkSpan(of view: some View, threshold: Double = 0.7) throws -> ClosedRange<CGFloat> {
        let staged = view.frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
        let out = try Snapshotter.png(of: staged, scale: 2)
        let bitmap = try #require(NSBitmapImageRep(data: out.png))
        let midY = Int(out.size.height)  // centre row, in pixels at 2×
        var first: Int?
        var last: Int?
        for x in 30..<(bitmap.pixelsWide - 30) {  // stay inside the border
            for y in (midY - 10)...(midY + 10) {
                let white = Double(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1)
                if white < threshold {
                    if first == nil { first = x }
                    last = x
                }
            }
        }
        let lo = try #require(first, "nothing was drawn")
        let hi = try #require(last)
        return (CGFloat(lo) / 2)...(CGFloat(hi) / 2)
    }

    @Test func thePlaceholderSitsWhereTypedTextWillAppear() throws {
        for alignment in [TextAlignment.leading, .center, .trailing] {
            let typed = try inkSpan(
                of: Input("Amount", text: .constant("0.00")).labelsHidden().multilineTextAlignment(alignment))
            let placeholder = try inkSpan(
                of: Input("Amount", text: .constant(""), prompt: "0.00").labelsHidden().multilineTextAlignment(
                    alignment))
            #expect(
                abs(typed.lowerBound - placeholder.lowerBound) <= 2,
                "\(alignment): typed text starts at \(typed.lowerBound)pt, the placeholder at \(placeholder.lowerBound)pt"
            )
        }
    }

    @Test func thePlaceholderSitsWhereTypedTextWillAppearWhenTheEnvironmentIsRTL() throws {
        let typed = try inkSpan(
            of: Input("Name", text: .constant("HHHH")).labelsHidden().environment(\.layoutDirection, .rightToLeft))
        let placeholder = try inkSpan(
            of: Input("Name", text: .constant(""), prompt: "HHHH").labelsHidden().environment(
                \.layoutDirection, .rightToLeft))
        #expect(
            abs(typed.lowerBound - placeholder.lowerBound) <= 2,
            "typed text starts at \(typed.lowerBound)pt, the placeholder at \(placeholder.lowerBound)pt")
    }

    @Test func aFrozenDisabledStateDimsTheLabelToo() throws {
        // `.interactionOverride(.disabled)` is how a disabled field gets photographed. It dimmed the box
        // but not the label (the label only listened to the real `isEnabled`), so a `StateRow` lied.
        func darkestLabelPixel(_ view: some View) throws -> Double {
            let staged = view.frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
            let bitmap = try #require(NSBitmapImageRep(data: try Snapshotter.png(of: staged, scale: 2).png))
            var darkest = 1.0
            for y in 24..<56 {  // the label row: 12pt padding, then a 12pt label, at 2×
                for x in 24..<140 {
                    darkest = min(
                        darkest, Double(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1))
                }
            }
            return darkest
        }
        let live = try darkestLabelPixel(Input("Email", text: .constant("")))
        let frozen = try darkestLabelPixel(Input("Email", text: .constant("")).interactionOverride(.disabled))
        #expect(live < 0.35, "precondition: an enabled label is near-black (got \(live))")
        #expect(frozen > live + 0.15, "frozen-disabled label is \(frozen), enabled is \(live) — it was not dimmed")
    }

    @Test func theHintNeverDoublesItsPunctuation() {
        // The library's own examples end their helper text with a full stop.
        let hint = FieldStatus(error: "Enter a full address.").accessibilityHint(
            description: "We never share it.", placeholder: "you@example.com")
        #expect(!hint.contains(".."), "hint reads: \(hint)")
    }

    @Test func aBlankDescriptionTakesNoRoom() {
        func height(_ description: String?) -> CGFloat {
            NSHostingView(rootView: Input("Label", text: .constant(""), description: description).frame(width: 200))
                .fittingSize.height
        }
        #expect(height(" ") == height(nil), "a whitespace-only description reserves an empty row")
    }
}
