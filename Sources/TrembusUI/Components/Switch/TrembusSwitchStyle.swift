import SwiftUI
import TrembusTokens

/// The Trembus switch — a STYLE for SwiftUI's own `Toggle`.
///
///     Toggle("Sync over cellular", isOn: $sync).toggleStyle(.trembus)
///     Toggle("Armed", isOn: $armed).toggleStyle(.trembus(tone: .danger))
///
/// The thumb stretches toward where it's going while held, then snaps home on a spring.
/// That stretch is the acknowledgement: you feel the control take the input before it commits.
public struct TrembusSwitchStyle: ToggleStyle {
    var tone: Tone

    public init(tone: Tone = .accent) {
        self.tone = tone
    }

    public func makeBody(configuration: Configuration) -> some View {
        SwitchBody(configuration: configuration, tone: tone)
    }
}

extension ToggleStyle where Self == TrembusSwitchStyle {
    public static var trembus: TrembusSwitchStyle { TrembusSwitchStyle() }

    public static func trembus(tone: Tone) -> TrembusSwitchStyle { TrembusSwitchStyle(tone: tone) }
}

// MARK: - Drawing

private struct SwitchBody: View {
    let configuration: ToggleStyleConfiguration
    let tone: Tone

    @Environment(\.theme) private var theme
    @Environment(\.controlSize) private var controlSize

    var body: some View {
        let metrics = ControlMetrics.switch(.init(controlSize))

        Pressable(action: { configuration.isOn.toggle() }) { state in
            HStack(spacing: Space.s3) {
                track(metrics, state)
                configuration.label
                    .font(.trembus(metrics.type))
                    .foregroundStyle(.theme(.text))
            }
            .opacity(state.isEnabled ? 1 : 0.6)
            .contentShape(Rectangle())
        }
        // VoiceOver and keyboard users get a real switch, not "button".
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }

    private func track(_ metrics: ControlMetrics.Switch, _ state: InteractionState) -> some View {
        let isOn = configuration.isOn
        // Held: the thumb reaches a quarter of the way toward the other side.
        let stretch = state.isPressed ? metrics.thumb * 0.25 : 0

        return Capsule()
            .fill(trackFill(isOn: isOn, state).color)
            .frame(width: metrics.width, height: metrics.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(.white)
                    .frame(width: metrics.thumb + stretch, height: metrics.thumb)
                    .elevation(.e1, in: Capsule())
                    .padding(metrics.inset)
            }
            .focusRing(state.isFocused, in: Capsule())
            .motion(Motion.calm(.base), value: state.phase)
            .motion(Motion.spring(.snap), value: isOn)
            .motion(Motion.spring(state.isPressed ? .press : .release), value: state.isPressed)
    }

    private func trackFill(isOn: Bool, _ state: InteractionState) -> ColorValue {
        let resolved = theme.tone(tone)
        let isLit = state.phase == .hover || state.phase == .pressed
        if isOn { return isLit ? resolved.hover : resolved.base }
        let off = theme.color.borderStrong
        return isLit ? off.mixed(with: theme.color.text, by: 0.18) : off
    }
}
