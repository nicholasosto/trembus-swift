import SwiftUI
import TrembusTokens

extension View {
    /// Lift this view off the page. Reads the shadow recipe from the current theme —
    /// light themes get soft stacked shadows, dark themes a deeper shadow plus a faint hairline.
    ///
    /// Apply it to a filled SHAPE (a card's background), not to a view with text in it —
    /// SwiftUI shadows every opaque pixel, glyphs included. `Surface` does this for you.
    public func elevation(_ level: Elevation, in shape: some InsettableShape = Rectangle())
        -> some View
    {
        modifier(ElevationModifier(level: level, shape: shape))
    }
}

private struct ElevationModifier<S: InsettableShape>: ViewModifier {
    @Environment(\.theme) private var theme
    let level: Elevation
    let shape: S

    func body(content: Content) -> some View {
        let style = theme.elevation[level]
        content
            // The token CSS never stacks more than two shadows per level.
            .modifier(ShadowLayerModifier(layer: style.shadows.first))
            .modifier(ShadowLayerModifier(layer: style.shadows.dropFirst().first))
            .overlay {
                if let hairline = style.hairline {
                    shape.strokeBorder(hairline.color, lineWidth: 1).allowsHitTesting(false)
                }
            }
    }
}

private struct ShadowLayerModifier: ViewModifier {
    let layer: ShadowLayer?

    func body(content: Content) -> some View {
        if let layer {
            content.shadow(color: layer.color.color, radius: layer.radius, x: layer.x, y: layer.y)
        } else {
            content
        }
    }
}
