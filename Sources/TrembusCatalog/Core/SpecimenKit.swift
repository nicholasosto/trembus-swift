import SwiftUI
import TrembusTokens
import TrembusUI

// Small helpers for writing specimens. Catalog chrome is built from the same tokens as the
// library — if a token is wrong, the catalog looks wrong too, which is the point.

/// A view with a quiet caption underneath.
public struct Labeled<Content: View>: View {
    private let caption: String
    private let content: Content

    public init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: Space.s3) {
            content
            Text(caption)
                .font(.trembus(.xs, family: .mono))
                .foregroundStyle(.theme(.textFaint))
        }
    }
}

/// The same control five times, frozen in each interaction state.
/// This is how a hover ends up in a still image.
public struct StateRow<Content: View>: View {
    private static var states: [(String, InteractionState)] {
        [
            ("rest", .rest), ("hover", .hovered), ("pressed", .pressed), ("focused", .focused),
            ("disabled", .disabled),
        ]
    }

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: Space.s6) {
            ForEach(Self.states, id: \.0) { name, state in
                Labeled(name) { content.interactionOverride(state) }
            }
        }
    }
}

/// A row with a fixed-width label on the left — for matrices (variant × state, tone × role).
public struct MatrixRow<Content: View>: View {
    private let title: String
    private let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Space.s5) {
            Text(title)
                .font(.trembus(.xs, family: .mono))
                .foregroundStyle(.theme(.textDim))
                .frame(width: 64, alignment: .leading)
            content
        }
    }
}
