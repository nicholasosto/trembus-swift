import SwiftUI
import TrembusTokens

extension View {
    /// Animate changes of `value` with a motion token — or with a short plain fade when the
    /// user has **Reduce Motion** on. Use this instead of `.animation(_:value:)` so every
    /// component honors the setting without thinking about it.
    ///
    ///     .motion(Motion.spring(.snap), value: isOn)
    ///
    /// `nil` means NO animation, with Reduce Motion on or off — for what must sit exactly under the
    /// pointer while it is dragged. (A zero-length animation is not the same thing: Reduce Motion
    /// would swap it for the fade, and the thing would trail the pointer.)
    public func motion<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

/// Which animation really runs. Plain logic, kept apart from the modifier so it can be tested.
nonisolated enum ReducedMotion {
    static func resolve(_ animation: Animation?, reduceMotion: Bool) -> Animation? {
        guard let animation else { return nil }
        return reduceMotion ? Motion.reduced : animation
    }
}

private struct MotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(ReducedMotion.resolve(animation, reduceMotion: reduceMotion), value: value)
    }
}
