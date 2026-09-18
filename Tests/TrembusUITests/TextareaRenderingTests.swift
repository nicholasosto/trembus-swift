import AppKit
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

@Suite("Textarea — rendering")
struct TextareaRenderingTests {
    /// Leftmost / rightmost column (in points) of anything darker than `threshold` on the first line of text.
    private func inkSpan(of view: some View, threshold: Double = 0.7) throws -> ClosedRange<CGFloat> {
        let staged = view.frame(width: 220).padding(12).background(Color.white).trembusTheme(.light)
        let bitmap = try #require(NSBitmapImageRep(data: try Snapshotter.png(of: staged, scale: 2).png))
        var first: Int?
        var last: Int?
        for x in 30..<(bitmap.pixelsWide - 30) {  // stay inside the border
            for y in 44..<76 {  // the first line: 12pt padding + 8pt box padding, then ~17pt of text, at 2×
                let white = Double(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1)
                if white < threshold {
                    if first == nil { first = x }
                    last = x
                }
            }
        }
        let lo = try #require(first, "nothing was drawn on the first line")
        let hi = try #require(last)
        return (CGFloat(lo) / 2)...(CGFloat(hi) / 2)
    }

    @Test func thePlaceholderSitsWhereTypedTextWillAppear() throws {
        for alignment in [TextAlignment.leading, .center, .trailing] {
            let typed = try inkSpan(
                of: Textarea("Notes", text: .constant("HHHH")).labelsHidden().multilineTextAlignment(alignment))
            let placeholder = try inkSpan(
                of: Textarea("Notes", text: .constant(""), prompt: "HHHH").labelsHidden().multilineTextAlignment(
                    alignment))
            #expect(
                abs(typed.lowerBound - placeholder.lowerBound) <= 2,
                "\(alignment): typed text starts at \(typed.lowerBound)pt, the placeholder at \(placeholder.lowerBound)pt"
            )
        }
    }

    @Test func thePlaceholderSitsWhereTypedTextWillAppearWhenTheEnvironmentIsRTL() throws {
        let typed = try inkSpan(
            of: Textarea("Notes", text: .constant("HHHH")).labelsHidden().environment(\.layoutDirection, .rightToLeft))
        let placeholder = try inkSpan(
            of: Textarea("Notes", text: .constant(""), prompt: "HHHH").labelsHidden().environment(
                \.layoutDirection, .rightToLeft))
        #expect(
            abs(typed.lowerBound - placeholder.lowerBound) <= 2,
            "typed text starts at \(typed.lowerBound)pt, the placeholder at \(placeholder.lowerBound)pt")
    }
}
