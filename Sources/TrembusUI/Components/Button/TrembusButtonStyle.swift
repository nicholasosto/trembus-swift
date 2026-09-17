import SwiftUI
import TrembusTokens

/// The Trembus button — a STYLE, so you keep SwiftUI's own `Button` and everything that
/// comes with it (roles, keyboard shortcuts, menus, accessibility).
///
///     Button("Save") { save() }.buttonStyle(.trembus)
///     Button("Delete", role: .destructive) { … }.buttonStyle(.trembus)     // → danger tone
///     Button("More") { … }.buttonStyle(.trembus(.ghost, tone: .neutral))
///         .controlSize(.small)
///
/// What it works out for itself:
/// - **tone** — `role: .destructive` becomes `.danger` unless you name a tone
/// - **size** — follows `.controlSize(_:)`
/// - **theme** — follows the environment, including system light/dark
/// - **motion** — springs under the pointer; plain fades when Reduce Motion is on
public struct TrembusButtonStyle: ButtonStyle {
    public enum Variant: String, CaseIterable, Sendable {
        /// Filled with the tone. The one primary action in a view.
        case solid
        /// Edged. A secondary action that still needs to look like a button.
        case outline
        /// Bare until hovered. Toolbars, rows, anything repeated.
        case ghost
    }

    var variant: Variant
    var tone: Tone?
    var isLoading: Bool
    var fullWidth: Bool

    /// - Parameters:
    ///   - tone: `nil` picks for you — `.danger` for destructive buttons, otherwise `.accent`.
    ///   - isLoading: shows a spinner and ignores clicks. Pair with your own in-flight guard
    ///     if the action can also be triggered from the keyboard.
    public init(
        _ variant: Variant = .solid, tone: Tone? = nil, isLoading: Bool = false,
        fullWidth: Bool = false
    ) {
        self.variant = variant
        self.tone = tone
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        InteractionReader(isPressed: configuration.isPressed) { state in
            StyledButton(configuration: configuration, style: self, state: state)
        }
    }
}

extension ButtonStyle where Self == TrembusButtonStyle {
    /// Solid accent — the default Trembus button.
    public static var trembus: TrembusButtonStyle { TrembusButtonStyle() }

    public static func trembus(
        _ variant: TrembusButtonStyle.Variant = .solid, tone: Tone? = nil, isLoading: Bool = false,
        fullWidth: Bool = false
    ) -> TrembusButtonStyle {
        TrembusButtonStyle(variant, tone: tone, isLoading: isLoading, fullWidth: fullWidth)
    }
}

// MARK: - Drawing

private struct StyledButton: View {
    let configuration: ButtonStyleConfiguration
    let style: TrembusButtonStyle
    let state: InteractionState

    @Environment(\.theme) private var theme
    @Environment(\.controlSize) private var controlSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let tone = theme.tone(style.tone ?? (configuration.role == .destructive ? .danger : .accent))
        let metrics = ControlMetrics.button(.init(controlSize))
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)

        HStack(spacing: Space.s3) {
            if style.isLoading {
                Spinner().frame(width: metrics.type.size, height: metrics.type.size)
            }
            configuration.label
        }
        .font(.trembus(metrics.type, weight: .semibold))
        .lineLimit(1)
        .padding(.horizontal, metrics.paddingX)
        .frame(height: metrics.height)
        .frame(maxWidth: style.fullWidth ? .infinity : nil)
        .foregroundStyle(ink(tone).color)
        .background(fill(tone).color, in: shape)
        .overlay(shape.strokeBorder(edge(tone).color, lineWidth: 1))
        .contentShape(shape)
        .focusRing(state.isFocused, in: shape)
        .opacity(state.isEnabled ? 1 : 0.55)
        .motion(Motion.calm(.fast), value: state)
        // Down fast with no bounce, back up with a little life.
        .scaleEffect(state.isPressed && !reduceMotion ? 0.97 : 1)
        .motion(Motion.spring(state.isPressed ? .press : .release), value: state.isPressed)
        .allowsHitTesting(!style.isLoading)
    }

    // The recipe is the web Button's, tone for tone.

    private func fill(_ tone: ToneColors) -> ColorValue {
        switch (style.variant, state.phase) {
        case (.solid, .pressed): tone.pressed
        case (.solid, .hover): tone.hover
        case (.solid, _): tone.base
        case (_, .hover), (_, .pressed): tone.bg
        default: tone.bg.opacity(0)
        }
    }

    private func edge(_ tone: ToneColors) -> ColorValue {
        switch (style.variant, state.phase) {
        case (.solid, _): fill(tone)
        case (.outline, .hover), (.outline, .pressed): tone.base
        case (.outline, _): theme.color.borderStrong
        case (.ghost, _): tone.base.opacity(0)
        }
    }

    private func ink(_ tone: ToneColors) -> ColorValue {
        style.variant == .solid ? tone.fg : tone.text
    }
}

/// The web's border spinner: three quarters of a ring, turning.
struct Spinner: View {
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(.foreground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.6).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
            .accessibilityHidden(true)
    }
}
