import SwiftUI
import TrembusTokens

/// A fill bar: how much of something, at a glance.
///
///     Meter(value: 0.64)
///     Meter(value: 42, in: 0...60, label: "Fuel", showsValue: true)
///     Meter(value: battery, tone: .levels(dangerBelow: 0.1, warningBelow: 0.25))
///
/// With `.levels`, the bar picks its own tone from the value — the state reveals itself,
/// the call site doesn't have to decide.
public struct Meter: View {
    /// How the bar chooses its color.
    public enum ToneRule: Sendable, Hashable {
        /// Always this tone.
        case fixed(Tone)
        /// By how full it is: below `dangerBelow` → danger, below `warningBelow` → warning,
        /// otherwise success. Fractions of the range, 0...1.
        case levels(dangerBelow: Double, warningBelow: Double)

        func tone(for fraction: Double) -> Tone {
            switch self {
            case .fixed(let tone): tone
            case .levels(let danger, let warning):
                fraction < danger ? .danger : fraction < warning ? .warning : .success
            }
        }
    }

    private let value: Double
    private let range: ClosedRange<Double>
    private let rule: ToneRule
    private let label: String?
    private let showsValue: Bool

    @Environment(\.controlSize) private var controlSize

    public init(
        value: Double, in range: ClosedRange<Double> = 0...1, tone: ToneRule = .fixed(.accent),
        label: String? = nil, showsValue: Bool = false
    ) {
        self.value = value
        self.range = range
        self.rule = tone
        self.label = label
        self.showsValue = showsValue
    }

    /// Where `value` sits in `range`, clamped to 0...1. An empty or inverted range reads as 0.
    var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0, value.isFinite else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    public var body: some View {
        let metrics = ControlMetrics.meter(.init(controlSize))
        let tone = rule.tone(for: fraction)

        VStack(alignment: .leading, spacing: Space.s2) {
            if label != nil || showsValue {
                HStack(alignment: .firstTextBaseline) {
                    if let label {
                        Text(label)
                            .font(.trembus(metrics.type, weight: .medium))
                            .foregroundStyle(.theme(.text))
                    }
                    Spacer(minLength: Space.s3)
                    if showsValue {
                        Text(percent)
                            .font(.trembus(metrics.type, family: .mono))
                            .monospacedDigit()
                            .foregroundStyle(.theme(.textDim))
                            .contentTransition(.numericText(value: fraction))
                    }
                }
            }
            Capsule()
                .fill(.theme(.surfaceSunken))
                .overlay(Capsule().strokeBorder(.theme(.borderSoft), lineWidth: 1))
                .frame(height: metrics.trackHeight)
                .overlay {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(.tone(tone))
                            // Never thinner than a dot, so a tiny value is still a visible mark.
                            .frame(
                                width: fraction == 0
                                    ? 0 : max(proxy.size.width * fraction, metrics.trackHeight)
                            )
                            // GeometryReader pins content top-LEFT and ignores layout direction; anchor the
                            // fill to the leading edge ourselves so it grows from the right under RTL.
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
        }
        .motion(Motion.calm(.slow), value: fraction)
        .motion(Motion.calm(.base), value: tone)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Meter")
        .accessibilityValue(percent)
        // Crossing into a new zone (danger / warning / success) is a threshold — mark it with a haptic.
        // A `.fixed` meter's tone never changes, so it never fires.
        .haptic(.level, trigger: tone)
    }

    private var percent: String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }
}
