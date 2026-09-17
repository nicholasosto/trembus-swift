import SwiftUI
import TrembusTokens

/// A small status label. Tone says what kind of state; the word says which.
///
///     Badge("Live", tone: .success, showsDot: true)
///     Badge("3 failed", tone: .danger, variant: .solid)
///
/// Tone is never the only signal: there is always a word, and when the user has
/// **Differentiate Without Color** on, the dot becomes a per-tone glyph.
public struct Badge: View {
    public enum Variant: String, CaseIterable, Sendable {
        /// Soft tint, tone-colored text. The default — quiet enough to repeat in a table.
        case soft
        /// Solid tone fill. Use sparingly: it shouts.
        case solid
        /// Tone-colored edge only. For dense rows where tints would stripe.
        case outline
    }

    private let title: String
    private let tone: Tone
    private let variant: Variant
    private let showsDot: Bool

    @Environment(\.controlSize) private var controlSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    public init(
        _ title: String, tone: Tone = .neutral, variant: Variant = .soft, showsDot: Bool = false
    ) {
        self.title = title
        self.tone = tone
        self.variant = variant
        self.showsDot = showsDot
    }

    public var body: some View {
        let metrics = ControlMetrics.badge(.init(controlSize))

        HStack(spacing: Space.s2) {
            if showsDot { marker(size: metrics.type.size) }
            Text(title)
        }
        .font(.trembus(metrics.type, weight: .medium))
        .lineLimit(1)
        .padding(.horizontal, metrics.paddingX)
        .frame(height: metrics.height)
        .foregroundStyle(.tone(tone, variant == .solid ? .fg : .text))
        .background(fill, in: Capsule())
        .overlay(Capsule().strokeBorder(.tone(tone).opacity(variant == .outline ? 1 : 0), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(tone.rawValue)
    }

    private var fill: AnyShapeStyle {
        switch variant {
        case .soft: AnyShapeStyle(.tone(tone, .bg))
        case .solid: AnyShapeStyle(.tone(tone))
        case .outline: AnyShapeStyle(.clear)
        }
    }

    @ViewBuilder
    private func marker(size: CGFloat) -> some View {
        if differentiateWithoutColor {
            Image(systemName: tone.symbolName)
                .font(.system(size: size - 2, weight: .bold))
        } else {
            Circle().frame(width: 6, height: 6)
        }
    }
}

extension Tone {
    /// The glyph that stands for this tone when color alone can't be relied on.
    nonisolated public var symbolName: String {
        switch self {
        case .accent: "star.fill"
        case .info: "info"
        case .success: "checkmark"
        case .warning: "exclamationmark"
        case .danger: "xmark"
        case .neutral: "minus"
        }
    }
}
