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
}
