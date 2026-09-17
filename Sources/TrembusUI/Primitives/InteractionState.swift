import SwiftUI
import TrembusTokens

/// Where a control is in its conversation with the pointer and keyboard.
/// Every interactive component draws itself from one of these — nothing else.
nonisolated public struct InteractionState: Sendable, Hashable {
    public var isHovered: Bool
    public var isPressed: Bool
    public var isFocused: Bool
    public var isEnabled: Bool

    public init(
        isHovered: Bool = false, isPressed: Bool = false, isFocused: Bool = false,
        isEnabled: Bool = true
    ) {
        self.isHovered = isHovered
        self.isPressed = isPressed
        self.isFocused = isFocused
        self.isEnabled = isEnabled
    }

    public static let rest = InteractionState()
    public static let hovered = InteractionState(isHovered: true)
    public static let pressed = InteractionState(isHovered: true, isPressed: true)
    public static let focused = InteractionState(isFocused: true)
    public static let disabled = InteractionState(isEnabled: false)

    /// One word for the pointer state — the web's `data-state`. Focus is separate, because
    /// a control can be focused AND hovered.
    public enum Phase: String, Sendable {
        case rest, hover, pressed, disabled
    }

    public var phase: Phase {
        if !isEnabled { return .disabled }
        if isPressed { return .pressed }
        if isHovered { return .hover }
        return .rest
    }
}

// MARK: - Forcing a state (for specimens and snapshots)

nonisolated private struct InteractionOverrideKey: EnvironmentKey {
    static let defaultValue: InteractionState? = nil
}

nonisolated extension EnvironmentValues {
    var interactionOverride: InteractionState? {
        get { self[InteractionOverrideKey.self] }
        set { self[InteractionOverrideKey.self] = newValue }
    }
}

extension View {
    /// Freeze every Trembus control in this subtree into one state.
    ///
    /// A hover can't be photographed — this is how the `States` specimen shows
    /// rest · hover · pressed · focused · disabled side by side in a still image.
    public func interactionOverride(_ state: InteractionState?) -> some View {
        environment(\.interactionOverride, state)
    }
}

// MARK: - Reading the live state

/// Tracks hover, focus, and enabled-ness, merges in `isPressed` from a style configuration,
/// and hands the content one `InteractionState`. Shared by every interactive component so
/// they all behave — and can all be frozen — the same way.
struct InteractionReader<Content: View>: View {
    var isPressed = false
    /// Where focus comes from. `nil` reads SwiftUI's `isFocused` environment — right INSIDE a
    /// button or toggle style. A text field wraps its control instead of living inside it, so
    /// it tracks focus with `@FocusState` and passes it in here.
    var focus: Bool?
    @ViewBuilder let content: (InteractionState) -> Content

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.interactionOverride) private var override

    var body: some View {
        content(override ?? live)
            .onHover { isHovered = $0 }
    }

    private var live: InteractionState {
        InteractionState(
            isHovered: isHovered && isEnabled, isPressed: isPressed && isEnabled,
            isFocused: (focus ?? isFocused) && isEnabled, isEnabled: isEnabled)
    }
}
