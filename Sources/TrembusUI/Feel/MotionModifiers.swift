import SwiftUI
import TrembusTokens

extension View {
    /// Animate changes of `value` with a motion token — or with a short plain fade when the
    /// user has **Reduce Motion** on. Use this instead of `.animation(_:value:)` so every
    /// component honors the setting without thinking about it.
    ///
    ///     .motion(Motion.spring(.snap), value: isOn)
    public func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

private struct MotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.reduced : animation, value: value)
    }
}
