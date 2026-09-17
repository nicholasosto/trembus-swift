import AppKit
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

// Rendering is part of the gate: a specimen that lays out to nothing, or paints nothing,
// fails here — before anyone has to notice it by eye.

// Not parameterized with `arguments:` on purpose — Swift Testing evaluates arguments off the
// main actor, and catalog entries (which hold view builders) can't leave it. Rendering is
// main-thread work anyway, so these loop and name the entry/specimen/theme in each failure.

@Suite("Rendering")
struct RenderTests {
    @Test func everySpecimenRendersInEveryTheme() {
        for entry in Catalog.entries {
            for specimen in entry.specimens {
                for theme in Theme.all {
                    let label = "\(entry.name)/\(specimen.name) [\(theme.name)]"
                    do {
                        let view = SpecimenStage(specimen, theme: theme).fixedSize()
                        let output = try Snapshotter.png(of: view, scale: 1)
                        #expect(output.size.width > 8 && output.size.height > 8, "\(label) is tiny")
                        #expect(output.inkCoverage > 0, "\(label) rendered blank")
                    } catch {
                        Issue.record("\(label) failed to render: \(error)")
                    }
                }
            }
        }
    }

    @Test func everyContactSheetRenders() {
        for entry in Catalog.entries {
            do {
                let output = try Snapshotter.png(of: EntrySheet(entry), scale: 1)
                #expect(output.inkCoverage > 0, "\(entry.name) sheet rendered blank")
            } catch {
                Issue.record("\(entry.name) sheet failed to render: \(error)")
            }
        }
    }

    @Test func themesActuallyChangeThePixels() throws {
        let specimen = try #require(CatalogEntry.button.specimen(named: "Default"))
        let renders = try Theme.all.map {
            try Snapshotter.png(of: SpecimenStage(specimen, theme: $0).fixedSize(), scale: 1).png
        }
        #expect(Set(renders).count == Theme.all.count, "two themes rendered identically")
    }

    @Test func aFrozenStateChangesThePixels() throws {
        func render(_ state: InteractionState) throws -> Data {
            let view = Button("Button") {}.buttonStyle(.trembus)
                .interactionOverride(state).padding(12).trembusTheme(.light)
            return try Snapshotter.png(of: view, scale: 1).png
        }
        let rest = try render(.rest)
        #expect(try render(.hovered) != rest, "hover looks the same as rest")
        #expect(try render(.pressed) != rest, "pressed looks the same as rest")
        #expect(try render(.focused) != rest, "focused looks the same as rest")
        #expect(try render(.disabled) != rest, "disabled looks the same as rest")
    }

    @Test func snapshotsHaveTruePixelDensityOnAnyDisplay() throws {
        // An offscreen window rasterizes TEXT at the main screen's scale, so on a 1× monitor a
        // "2×" snapshot used to be a soft enlargement (and differed from a Retina machine's).
        // `Snapshotter` now forces the scale on the layer tree. The probe: crisp glyph stems
        // go white → black within one pixel; enlarged ones take several.
        //
        // Measured on a 1× display:  fix on → 0.98   fix off → 0.70   (threshold sits between)
        // Only TEXT discriminates — plain `Color` views and `Canvas` stay crisp either way.
        let view = Text("HIHIHI").font(.system(size: 40, weight: .bold)).foregroundStyle(.black)
            .frame(width: 200, height: 50).background(.white)
        let output = try Snapshotter.png(of: view, scale: 2)
        let bitmap = try #require(NSBitmapImageRep(data: output.png))
        #expect(bitmap.pixelsWide == 400 && bitmap.pixelsHigh == 100)

        let middleRow = (0..<bitmap.pixelsWide).map { x in
            Double(bitmap.colorAt(x: x, y: 50)?.usingColorSpace(.deviceGray)?.whiteComponent ?? 1)
        }
        let sharpestEdge = zip(middleRow, middleRow.dropFirst()).map { abs($0 - $1) }.max() ?? 0
        #expect(
            sharpestEdge > 0.85, "sharpest glyph edge is \(sharpestEdge) — text was rasterized below 2× and enlarged")
    }

    @Test func anUnboundedLayoutIsReportedNotRendered() {
        // A bare flexible shape has no size of its own — the classic missing `.frame(width:)`.
        #expect(throws: Snapshotter.Failure.self) {
            try Snapshotter.png(of: Color.red.frame(maxWidth: .infinity, maxHeight: .infinity).frame(minWidth: 9000))
        }
    }
}
