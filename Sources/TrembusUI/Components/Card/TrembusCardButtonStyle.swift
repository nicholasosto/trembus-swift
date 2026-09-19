import SwiftUI
import TrembusTokens

/// Makes a whole `Card` pressable — a STYLE, so you keep SwiftUI's own `Button` and everything that
/// comes with it (keyboard, roles, VoiceOver, `.disabled`).
///
///     Button { open(project) } label: {
///         Card(project.name) { Meter(value: project.progress) }
///     }
///     .buttonStyle(.trembusCard)
///
/// Hover lifts the card one step and firms its edge; pressing settles it back down.
/// A pressable card holds NO controls of its own — a button inside a button can't be reached.
/// Put the actions in a plain card's footer instead.
public struct TrembusCardButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        InteractionReader(isPressed: configuration.isPressed) { state in
            let shape = RoundedRectangle(cornerRadius: Radius.lg.value, style: .continuous)
            configuration.label
                .environment(\.cardInteraction, state)
                .contentShape(shape)
                .focusRing(state.isFocused, in: shape)
                .opacity(state.isEnabled ? 1 : Opacity.disabled)
                .motion(Motion.calm(.fast), value: state)
        }
    }
}

extension ButtonStyle where Self == TrembusCardButtonStyle {
    /// A `Card` as the button's label, lifted on hover.
    public static var trembusCard: TrembusCardButtonStyle { TrembusCardButtonStyle() }
}

// MARK: - How the style tells the card inside it what the pointer is doing

nonisolated private struct CardInteractionKey: EnvironmentKey {
    static let defaultValue = InteractionState.rest
}

nonisolated extension EnvironmentValues {
    var cardInteraction: InteractionState {
        get { self[CardInteractionKey.self] }
        set { self[CardInteractionKey.self] = newValue }
    }
}
