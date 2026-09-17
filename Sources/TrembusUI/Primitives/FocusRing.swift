import SwiftUI
import TrembusTokens

extension View {
    /// The Trembus focus ring: 2pt, in the theme's `focusRing` color, floating 2pt outside
    /// the control — the same `outline: 2px; outline-offset: 2px` the web components use.
    public func focusRing(_ isFocused: Bool, in shape: some InsettableShape) -> some View {
        overlay {
            shape
                .inset(by: -3)  // 2pt gap + half of the 2pt stroke
                .stroke(.theme(.focusRing), lineWidth: 2)
                .opacity(isFocused ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)  // decoration, not content
        }
    }

    /// The FIELD focus ring: 2pt HUGGING the edge and softened — the web's
    /// `box-shadow: 0 0 0 2px color-mix(focus-ring 55%)`. Buttons get a floating ring because
    /// they sit in rows of lookalikes; a field is already a big obvious box, so its ring only
    /// needs to thicken the edge. Turns danger-toned when the field is invalid.
    public func fieldFocusRing(_ isFocused: Bool, isInvalid: Bool = false, in shape: some InsettableShape)
        -> some View
    {
        overlay {
            shape
                .inset(by: -1)  // half of the 2pt stroke: the ring starts exactly at the edge
                .stroke(
                    isInvalid
                        ? AnyShapeStyle(.tone(.danger).opacity(0.45)) : AnyShapeStyle(.theme(.focusRing).opacity(0.55)),
                    lineWidth: 2
                )
                .opacity(isFocused ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
