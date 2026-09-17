import AppKit
import SwiftUI
import Testing

@testable import TrembusCatalog
@testable import TrembusTokens
@testable import TrembusUI

// Rendering in every theme and the contract are already covered for Card by RenderTests
// and ContractTests. This file is for its OWN LOGIC: how a pressable card answers the
// pointer, and what its slots leave behind.

@Suite("Card")
@MainActor
struct CardTests {
    @Test("rest, hover and pressed each look different; focus and disabled never lift")
    func emphasisFollowsThePointer() {
        #expect(InteractionState.rest.cardEmphasis == .none)
        #expect(InteractionState.hovered.cardEmphasis == .lifted)
        #expect(InteractionState.pressed.cardEmphasis == .firm)
        #expect(InteractionState.focused.cardEmphasis == .none)
        #expect(InteractionState.disabled.cardEmphasis == .none)
        #expect(InteractionState(isHovered: true, isPressed: true, isEnabled: false).cardEmphasis == .none)
    }

    // MARK: - Layout regressions (found by the adversarial review; each seen failing first)

    private func fittedHeight(_ view: some View) -> CGFloat {
        NSHostingView(rootView: view.frame(width: 240).trembusTheme(.dark)).fittingSize.height
    }

    @Test("a slot with several views is ONE section — not one padded band per view")
    func aSlotWithSeveralViewsIsStillOneSection() {
        let stacked = Card {
            VStack(alignment: .leading, spacing: Space.s0) {
                Text("Line one")
                Text("Line two")
            }
        } header: {
            VStack(alignment: .leading, spacing: Space.s0) {
                Text("Deploy")
                Text("sub")
            }
        }
        let loose = Card {
            Text("Line one")
            Text("Line two")
        } header: {
            Text("Deploy")
            Text("sub")
        }
        #expect(fittedHeight(loose) == fittedHeight(stacked))
    }

    @Test("a slot whose closure produced nothing leaves no band, no gap and no hairline")
    func anEmptySlotLeavesNoTrace() {
        func card(showsHeader: Bool, showsFooter: Bool) -> some View {
            Card {
                Text("Body")
            } header: {
                if showsHeader { Text("Header") }
            } footer: {
                if showsFooter { Text("Footer") }
            }
        }
        let bodyOnly = fittedHeight(Card { Text("Body") })
        #expect(fittedHeight(card(showsHeader: false, showsFooter: false)) == bodyOnly)
        #expect(
            fittedHeight(card(showsHeader: true, showsFooter: false)) == fittedHeight(Card("Header") { Text("Body") }))
        #expect(
            fittedHeight(card(showsHeader: true, showsFooter: true))
                > fittedHeight(card(showsHeader: true, showsFooter: false)))
    }

    @Test("only the card that IS the button's label answers the pointer — cards nested inside it stay at rest")
    func aCardNestedInAPressableCardStaysAtRest() throws {
        func pressable(inner: some View) -> some View {
            Button {
            } label: {
                Card("Project") { inner }.frame(width: 240)
            }
            .buttonStyle(.trembusCard)
            .interactionOverride(.hovered)
            .padding(Space.s5)
            .trembusTheme(.light)
        }
        let nested = try Snapshotter.png(of: pressable(inner: Card { Text("12") }), scale: 2).png
        let pinnedAtRest = try Snapshotter.png(
            of: pressable(inner: Card { Text("12") }.environment(\.cardInteraction, .rest)), scale: 2
        ).png
        #expect(nested == pinnedAtRest)
    }
}
