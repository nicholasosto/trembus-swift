import SwiftUI
import TrembusTokens

/// The press primitive: a real button that hands your label its live `InteractionState`.
///
/// Build custom controls on this instead of `onTapGesture` — you get keyboard activation,
/// focus, the button accessibility trait, and freezable states for free.
///
///     Pressable(action: open) { state in
///         Row(title: "Inbox", highlighted: state.isHovered)
///             .focusRing(state.isFocused, in: .rect(cornerRadius: Radius.md.value))
///     }
public struct Pressable<Label: View>: View {
    private let action: () -> Void
    private let label: (InteractionState) -> Label

    public init(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (InteractionState) -> Label
    ) {
        self.action = action
        self.label = label
    }

    public var body: some View {
        // The resting label doubles as the accessibility label source; what is actually
        // drawn is the style body below, which knows the live state.
        Button(action: action) { label(.rest) }
            .buttonStyle(PressableStyle(label: label))
    }
}

private struct PressableStyle<Label: View>: ButtonStyle {
    let label: (InteractionState) -> Label

    func makeBody(configuration: Configuration) -> some View {
        InteractionReader(isPressed: configuration.isPressed) { state in
            label(state)
        }
    }
}
