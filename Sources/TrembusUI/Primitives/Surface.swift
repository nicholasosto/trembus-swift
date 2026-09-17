import SwiftUI
import TrembusTokens

/// How a `Surface` sits relative to the page.
/// (Top-level, not nested: a type nested in generic `Surface<Content>` would be a
/// different type for every `Content`.)
public enum SurfaceLevel: String, CaseIterable, Sendable {
    /// Sits on the page. Fill + edge, no lift.
    case flat
    /// A card. Lifted one step.
    case raised
    /// A well, pressed into the page.
    case sunken
    /// Floats above everything — popovers, menus, dialogs.
    case overlay
    /// Translucent. Liquid Glass on macOS 26+, a system material before that.
    case glass
}

/// How much a `.raised` surface answers the pointer — for surfaces that can be pressed, like a card
/// used as a button's label. Only `.raised` has somewhere to lift to; other levels ignore it.
public enum SurfaceEmphasis: String, CaseIterable, Sendable {
    case none
    /// A firmer edge, no lift: held down.
    case firm
    /// A firmer edge and one step higher: the pointer is over it (the web's `.tcl-card--interactive:hover`).
    case lifted
}

/// The box primitive: a themed backdrop with the right fill, edge, and lift for its level.
///
///     Surface(.raised) { Text("A card") }
///     Surface(.sunken, padding: Space.s3) { … }   // a well: inputs, code, inset lists
///     Surface(.raised, padding: Space.s0, clipsContent: true) { … }   // edge-to-edge content (Card)
public struct Surface<Content: View>: View {
    public typealias Level = SurfaceLevel

    private let level: Level
    private let radius: Radius
    private let padding: CGFloat
    private let clipsContent: Bool
    private let emphasis: SurfaceEmphasis
    private let content: Content

    public init(
        _ level: Level = .flat, radius: Radius = .lg, padding: CGFloat = Space.s5,
        clipsContent: Bool = false, emphasis: SurfaceEmphasis = .none,
        @ViewBuilder content: () -> Content
    ) {
        self.level = level
        self.radius = radius
        self.padding = padding
        self.clipsContent = clipsContent
        self.emphasis = emphasis
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius.value, style: .continuous)
        padded(shape)
            .background { backdrop(shape) }
            .overlay {
                // Clipped content may run edge to edge (a card's header band) and would paint over the
                // backdrop's edge — so it is drawn once more on top. The border tokens are opaque.
                if clipsContent, let edge {
                    shape.strokeBorder(.theme(edge), lineWidth: 1).allowsHitTesting(false)
                }
            }
    }

    private var edge: ColorToken? {
        switch level {
        case .flat, .overlay: .border
        case .raised: emphasis == .none ? .border : .borderStrong
        case .sunken: .borderSoft
        case .glass: nil
        }
    }

    /// Off by default: clipping would also cut a child's focus ring where it reaches past the edge.
    /// Only the content is clipped — the lift lives on the backdrop, so the shadow survives.
    @ViewBuilder
    private func padded(_ shape: RoundedRectangle) -> some View {
        if clipsContent {
            content.padding(padding).clipShape(shape)
        } else {
            content.padding(padding)
        }
    }

    @ViewBuilder
    private func backdrop(_ shape: RoundedRectangle) -> some View {
        switch level {
        case .flat:
            shape.fill(.theme(.surface))
                .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
        case .raised:
            shape.fill(.theme(.surfaceRaised))
                .overlay(shape.strokeBorder(.theme(edge ?? .border), lineWidth: 1))
                .elevation(emphasis == .lifted ? .e2 : .e1, in: shape)
        case .sunken:
            shape.fill(.theme(.surfaceSunken))
                .overlay(shape.strokeBorder(.theme(.borderSoft), lineWidth: 1))
        case .overlay:
            shape.fill(.theme(.surfaceRaised))
                .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
                .elevation(.e3, in: shape)
        case .glass:
            if #available(macOS 26.0, *) {
                Color.clear.glassEffect(.regular, in: shape)
            } else {
                shape.fill(.regularMaterial)
                    .overlay(shape.strokeBorder(.theme(.borderSoft), lineWidth: 1))
            }
        }
    }
}
