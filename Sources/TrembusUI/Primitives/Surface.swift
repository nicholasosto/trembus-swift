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

/// The box primitive: a themed backdrop with the right fill, edge, and lift for its level.
///
///     Surface(.raised) { Text("A card") }
///     Surface(.sunken, padding: Space.s3) { … }   // a well: inputs, code, inset lists
public struct Surface<Content: View>: View {
    public typealias Level = SurfaceLevel

    private let level: Level
    private let radius: Radius
    private let padding: CGFloat
    private let content: Content

    public init(
        _ level: Level = .flat, radius: Radius = .lg, padding: CGFloat = Space.s5,
        @ViewBuilder content: () -> Content
    ) {
        self.level = level
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius.value, style: .continuous)
        content
            .padding(padding)
            .background { backdrop(shape) }
    }

    @ViewBuilder
    private func backdrop(_ shape: RoundedRectangle) -> some View {
        switch level {
        case .flat:
            shape.fill(.theme(.surface))
                .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
        case .raised:
            shape.fill(.theme(.surfaceRaised))
                .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
                .elevation(.e1, in: shape)
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
