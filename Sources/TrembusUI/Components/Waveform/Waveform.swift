import SwiftUI
import TrembusTokens

/// The shape of a sound: a wave you can play and drag a playhead through. It draws what it is GIVEN —
/// peaks, progress, playing — and never opens a file or a player, so every state is plain data.
/// Not a Meter: a Meter says how much there is; a Waveform says where you are in something that plays.
///
///     Waveform("Interview, take 3", source: .peaks(peaks), progress: $progress, isPlaying: $isPlaying, duration: 24)
///     Waveform("Interview, take 3", source: .loading, progress: $progress, isPlaying: $isPlaying)
///     Waveform(compact: "Interview, take 3", source: .peaks(peaks))      // the wave alone — a thumbnail
///
/// You own the player. Watch `isPlaying` and `progress`, drive your `AVAudioPlayer` from them, and write
/// `progress` back as the sound moves. The web's `AudioWaveform` holds its own `<audio>`; here the library
/// stays free of AVFoundation, and the stills on a contact sheet can never drift from the real thing.
public struct Waveform: View {
    /// What there is to draw.
    nonisolated public enum Source: Sendable, Hashable {
        /// The peaks are still being read. Draws a quiet, dormant shape and says so in words.
        case loading
        /// The peaks could not be read. The reason is shown and spoken; blank falls back to a plain one.
        case failed(String)
        /// Loudness over time, each 0...1, any count — it is fitted to the width. Empty draws dormant.
        case peaks([Double])
    }

    private let label: String
    private let source: Source
    private let tone: Tone
    private let duration: TimeInterval?
    private let playsOnRelease: Bool
    private let isCompact: Bool
    @Binding private var progress: Double
    @Binding private var isPlaying: Bool

    @FocusState private var isWaveFocused: Bool
    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.interactionOverride) private var override

    /// - Parameters:
    ///   - label: the name of the sound. Always shown — tone is never the only signal.
    ///   - progress: where the playhead is, 0...1. Dragging the wave and the arrow keys write it.
    ///   - isPlaying: the play button and Space write it; so does letting go of the wave (see `playsOnRelease`).
    ///   - duration: seconds, for the `0:09 / 0:24` readout and 5-second key steps. `nil` reads `--:--`.
    ///   - playsOnRelease: letting go of the wave starts playback from there. Keyboard seeks never do.
    public init(
        _ label: String, source: Source, progress: Binding<Double>, isPlaying: Binding<Bool>,
        duration: TimeInterval? = nil, tone: Tone = .accent, playsOnRelease: Bool = true
    ) {
        self.label = label
        self.source = source
        self.tone = tone
        self.duration = duration
        self.playsOnRelease = playsOnRelease
        self.isCompact = false
        self._progress = progress
        self._isPlaying = isPlaying
    }

    /// The wave alone: no button, no playhead, not focusable — a picture of the sound, for a tile.
    public init(compact label: String, source: Source, tone: Tone = .accent) {
        self.label = label
        self.source = source
        self.tone = tone
        self.duration = nil
        self.playsOnRelease = false
        self.isCompact = true
        self._progress = .constant(0)
        self._isPlaying = .constant(false)
    }

    public var body: some View {
        let metrics = ControlMetrics.waveform(.init(controlSize))
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)

        Group {
            if isCompact { compact(metrics) } else { player(metrics) }
        }
        .background(.theme(.surface), in: shape)
        .overlay(shape.strokeBorder(edge, lineWidth: 1))
        // A frozen state (for stills) must dim the box exactly as the real one does.
        .opacity(boxIsEnabled ? 1 : Opacity.disabled)
        // Watch the status LINE, not the source: comparing thousands of peaks on every tick of a playing
        // sound would be work for nothing.
        .motion(Motion.calm(.fast), value: WaveformText.status(source))
    }

    // MARK: - The two faces

    private func player(_ metrics: ControlMetrics.Waveform) -> some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
                Text(label)
                    .font(.trembus(metrics.type, weight: .medium))
                    .foregroundStyle(.theme(.text))
                    .lineLimit(1)
                    .accessibilityHidden(true)  // the button and the scrubber carry the name
                Spacer(minLength: Space.s3)
                status(metrics)
            }
            HStack(spacing: Space.s4) {
                toggle(metrics)
                scrubber(metrics)
                // The widest it will ever be holds the room, so the wave beside it never re-fits its bars
                // when `--:--` becomes `0:00 / 0:24`.
                Text(WaveformText.widestReadout(duration: duration))
                    .hidden()
                    .overlay(alignment: .trailing) {
                        Text(WaveformText.readout(progress: progress, duration: isReady ? duration : nil))
                            .foregroundStyle(.theme(.textDim))
                    }
                    .font(.trembus(metrics.type, family: .mono))
                    .monospacedDigit()
                    .fixedSize()
                    .accessibilityHidden(true)  // the scrubber speaks it
            }
        }
        .padding(Space.s4)
        // The web marks the status `aria-live`. Same effect: say it the moment it CHANGES, and say which
        // sound. The player only — a wall of compact thumbnails must not all talk at once.
        .onChange(of: WaveformText.status(source)) { _, _ in
            if let words = WaveformText.announcement(label, source: source) {
                AccessibilityNotification.Announcement(words).post()
            }
        }
    }

    private func compact(_ metrics: ControlMetrics.Waveform) -> some View {
        WaveTrack(source: source, fraction: 0, tone: tone, metrics: metrics, isCompact: true)
            .frame(height: metrics.compactHeight)
            .overlay {
                // No room for a word here, so a glyph carries "failed" — never the red edge alone.
                if case .failed = source {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.trembus(metrics.type))
                        .foregroundStyle(.tone(.danger, .text))
                }
            }
            .padding(Space.s2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WaveformText.compactName(label, source: source))
            .accessibilityAddTraits(.isImage)
    }

    // MARK: - Parts

    @ViewBuilder private func status(_ metrics: ControlMetrics.Waveform) -> some View {
        if let text = WaveformText.status(source) {
            HStack(spacing: Space.s2) {
                if case .failed = source {
                    Image(systemName: "exclamationmark.triangle.fill")
                } else {
                    Spinner().frame(width: metrics.type.size, height: metrics.type.size)
                }
                Text(text).lineLimit(1)
            }
            .font(.trembus(metrics.type))
            .foregroundStyle(isFailed ? AnyShapeStyle(.tone(.danger, .text)) : AnyShapeStyle(.theme(.textDim)))
            .transition(.opacity)
            .accessibilityHidden(true)  // announced when it appears, and part of the scrubber's value
        }
    }

    private func toggle(_ metrics: ControlMetrics.Waveform) -> some View {
        Pressable(action: { isPlaying.toggle() }) { state in
            PlayToggle(
                state: state, isPlaying: isPlaying, tone: tone, metrics: metrics,
                // The whole box already dims when disabled; don't dim the button twice.
                dimsItself: boxIsEnabled)
        }
        // Nothing to play means no Play — but a sound that is ALREADY playing (its peaks still loading, or
        // failed) must always be stoppable.
        .disabled(!isReady && !isPlaying)
        .accessibilityLabel(WaveformText.toggleName(label, isPlaying: isPlaying))
    }

    private func scrubber(_ metrics: ControlMetrics.Waveform) -> some View {
        let ring = RoundedRectangle(cornerRadius: Radius.sm.value, style: .continuous)
        let onScrub: ((Double) -> Void)? = isReady ? { progress = $0 } : nil
        return InteractionReader(focus: isWaveFocused) { state in
            WaveTrack(
                source: source, fraction: WaveformMath.fraction(progress), tone: tone, metrics: metrics,
                isHovered: state.isHovered && isReady,
                onScrub: onScrub,
                onRelease: { if playsOnRelease, isReady { isPlaying = true } }
            )
            .frame(height: metrics.waveHeight)
            .focusRing(state.isFocused, in: ring)
        }
        // Like a button: Tab reaches it when Keyboard navigation is on; a click does not ring it.
        .focusable(isReady, interactions: .activate)
        .focused($isWaveFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.down, .repeat]) { press in
            guard isReady else { return .ignored }
            if press.key.character == KeyEquivalent.space.character {
                // Once per press: held down, Space must not flap between play and pause.
                if WaveformMath.togglesPlayback(press.key, isRepeat: press.phase == .repeat) { isPlaying.toggle() }
                return .handled
            }
            guard let move = WaveformMath.Move(press.key) else { return .ignored }
            // A keyboard seek moves the playhead and never starts sound.
            progress = WaveformMath.seek(move, from: progress, duration: duration)
            return .handled
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WaveformText.name(label))
        .accessibilityValue(WaveformText.spokenValue(progress: progress, duration: duration, source: source))
        .accessibilityAdjustableAction { direction in
            guard isReady else { return }
            switch direction {
            case .increment: progress = WaveformMath.seek(.forward, from: progress, duration: duration)
            case .decrement: progress = WaveformMath.seek(.back, from: progress, duration: duration)
            @unknown default: break
            }
        }
    }

    // MARK: - State

    /// There is a real wave to play and seek through.
    var isReady: Bool {
        if case .peaks(let peaks) = source { return !peaks.isEmpty }
        return false
    }

    private var isFailed: Bool {
        if case .failed = source { return true }
        return false
    }

    private var boxIsEnabled: Bool { override?.isEnabled ?? isEnabled }

    private var edge: AnyShapeStyle {
        isFailed ? AnyShapeStyle(.tone(.danger)) : AnyShapeStyle(.theme(.border))
    }
}

// MARK: - The play / pause button

private struct PlayToggle: View {
    let state: InteractionState
    let isPlaying: Bool
    let tone: Tone
    let metrics: ControlMetrics.Waveform
    let dimsItself: Bool

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let colors = theme.tone(tone)

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.trembus(metrics.glyph))
            // Playing is a FILLED button: the state is a shape change, not just a glyph swap.
            .foregroundStyle((isPlaying ? colors.fg : colors.text).color)
            .frame(width: metrics.toggle, height: metrics.toggle)
            .background(fill(colors).color, in: Circle())
            .overlay(Circle().strokeBorder((isPlaying ? fill(colors) : theme.color.border).color, lineWidth: 1))
            .contentShape(Circle())
            .focusRing(state.isFocused, in: Circle())
            .opacity(state.isEnabled || !dimsItself ? 1 : Opacity.disabled)
            .motion(Motion.calm(.fast), value: state)
            .motion(Motion.calm(.fast), value: isPlaying)
            .scaleEffect(state.isPressed && !reduceMotion ? 0.97 : 1)
            .motion(Motion.spring(state.isPressed ? .press : .release), value: state.isPressed)
    }

    private func fill(_ colors: ToneColors) -> ColorValue {
        switch (isPlaying, state.phase) {
        case (true, .pressed): colors.pressed
        case (true, .hover): colors.hover
        case (true, _): colors.base
        case (false, .pressed): theme.color.surfaceSunken
        case (false, .hover): theme.color.surfaceHover
        case (false, _): theme.color.surfaceRaised
        }
    }
}

// MARK: - The wave

/// Bars, the played part painted over them, and the playhead. Time runs left to right in every
/// language — a player's timeline does not mirror — so this one strip is pinned to left-to-right.
private struct WaveTrack: View {
    let source: Waveform.Source
    let fraction: Double
    let tone: Tone
    let metrics: ControlMetrics.Waveform
    var isCompact = false
    var isHovered = false
    var onScrub: ((Double) -> Void)?
    var onRelease: () -> Void = {}

    /// `@GestureState`, not `@State`: it falls back to false by itself when a drag is CUT SHORT (the wave
    /// stops being ready, or is disabled, with the mouse still down) — a case `onEnded` never hears about.
    @GestureState private var isScrubbing = false
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let colors = theme.tone(tone)
        let bars = WaveBars(peaks: peaks, metrics: metrics)

        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                bars.fill(base(colors).color)
                if !isCompact, peaks != nil {
                    bars.fill(colors.base.color)
                        .mask(alignment: .leading) { Rectangle().frame(width: width * fraction) }
                    RoundedRectangle(cornerRadius: metrics.playhead / 2, style: .continuous)
                        .fill(colors.base.color)
                        .frame(width: metrics.playhead, height: proxy.size.height + metrics.playhead * 2)
                        .offset(x: width * fraction - metrics.playhead / 2)
                }
            }
            .frame(width: width, height: proxy.size.height, alignment: .leading)
            // A playhead follows TIME, so it moves at a constant speed — and not at all behind a drag:
            // under the pointer it must sit exactly where the pointer is.
            // `nil`, not a zero-length animation: Reduce Motion would swap that for its fade, and trail.
            .motion(isScrubbing ? nil : .linear(duration: Motion.Duration.fast.seconds), value: fraction)
            .motion(Motion.calm(.fast), value: isHovered)
            .contentShape(Rectangle())
            .gesture(scrub(width: width), isEnabled: onScrub != nil && isEnabled)
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    /// Real peaks, or `nil` for the dormant shape.
    private var peaks: [Double]? {
        if case .peaks(let peaks) = source, !peaks.isEmpty { return peaks }
        return nil
    }

    /// The bars underneath. The web's recipe: the tone mixed into the sunken surface — fainter still when
    /// dormant, so a placeholder reads as inert rather than "nothing played yet". A compact wave has no
    /// playhead to contrast with, so it wears the full tone.
    private func base(_ colors: ToneColors) -> ColorValue {
        let share =
            if peaks == nil {
                isCompact ? WaveformInk.muted : WaveformInk.dormant
            } else if isCompact {
                1.0
            } else {
                isHovered || isScrubbing ? WaveformInk.hovered : WaveformInk.muted
            }
        return theme.color.surfaceSunken.mixed(with: colors.base, by: share)
    }

    private func scrub(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isScrubbing) { _, isScrubbing, _ in isScrubbing = true }
            .onChanged { value in
                guard width > 0 else { return }
                onScrub?(WaveformMath.fraction(value.location.x / width))
            }
            .onEnded { _ in onRelease() }
    }
}

/// How much of the tone goes into the unplayed bars. `dormant` and `muted` are the web's `color-mix`
/// percentages; `hovered` is this library's own.
nonisolated private enum WaveformInk {
    static let dormant = 0.22
    static let muted = 0.34
    /// Under the pointer the unplayed bars step up: "you can grab this".
    static let hovered = 0.5
}

/// Centered, round-ended bars, as many as fit the width.
nonisolated private struct WaveBars: Shape {
    /// `nil` draws the dormant shape.
    let peaks: [Double]?
    let metrics: ControlMetrics.Waveform

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        let count = metrics.barCount(in: rect.width)
        let barWidth = metrics.barWidth
        let levels = peaks.map { WaveformMath.bars(from: $0, count: count) } ?? WaveformMath.dormant(count: count)
        let slot = rect.width / CGFloat(count)
        let corner = CGSize(width: barWidth / 2, height: barWidth / 2)

        var path = Path()
        for (index, level) in levels.enumerated() {
            // Never shorter than a dot, so silence is still a visible mark.
            let height = max(barWidth, rect.height * level)
            let bar = CGRect(
                x: rect.minX + CGFloat(index) * slot + (slot - barWidth) / 2, y: rect.midY - height / 2,
                width: barWidth, height: height)
            path.addRoundedRect(in: bar, cornerSize: corner)
        }
        return path
    }
}

// MARK: - Logic (plain, so it can be tested directly)

nonisolated enum WaveformMath {
    /// Seconds per arrow key and per Page key — the web's. With no duration, the same share of 100 seconds.
    static let stepSeconds = 5.0
    static let pageSeconds = 10.0
    private static let assumedDuration = 100.0

    enum Move: Sendable {
        case back, forward, pageBack, pageForward, start, end

        /// Up means forward and Down means back, as on a native slider.
        init?(_ key: KeyEquivalent) {
            switch key.character {
            case KeyEquivalent.rightArrow.character, KeyEquivalent.upArrow.character: self = .forward
            case KeyEquivalent.leftArrow.character, KeyEquivalent.downArrow.character: self = .back
            case KeyEquivalent.pageUp.character: self = .pageForward
            case KeyEquivalent.pageDown.character: self = .pageBack
            case KeyEquivalent.home.character: self = .start
            case KeyEquivalent.end.character: self = .end
            default: return nil
            }
        }
    }

    /// Space plays or pauses — once per press, never on key repeat.
    static func togglesPlayback(_ key: KeyEquivalent, isRepeat: Bool) -> Bool {
        key.character == KeyEquivalent.space.character && !isRepeat
    }

    /// `progress` as a drawable fraction: clamped to 0...1, and anything not finite reads as 0.
    static func fraction(_ progress: Double) -> Double {
        progress.isFinite ? min(max(progress, 0), 1) : 0
    }

    /// A usable duration, or `nil`: zero, negative and non-finite all mean "not known yet".
    static func valid(_ duration: TimeInterval?) -> TimeInterval? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        return duration
    }

    static func seek(_ move: Move, from progress: Double, duration: TimeInterval?) -> Double {
        let here = fraction(progress)
        let total = valid(duration) ?? assumedDuration
        return switch move {
        case .start: 0
        case .end: 1
        case .back: fraction(here - stepSeconds / total)
        case .forward: fraction(here + stepSeconds / total)
        case .pageBack: fraction(here - pageSeconds / total)
        case .pageForward: fraction(here + pageSeconds / total)
        }
    }

    /// Fit any number of peaks to `count` bars. Each bar takes the LOUDEST peak in its stretch, so a
    /// single clap is never averaged away; with fewer peaks than bars, neighbors repeat.
    static func bars(from peaks: [Double], count: Int) -> [Double] {
        guard count > 0, !peaks.isEmpty else { return [] }
        return (0..<count).map { bar in
            let start = bar * peaks.count / count
            let end = max(start + 1, (bar + 1) * peaks.count / count)
            return peaks[start..<min(end, peaks.count)].reduce(0) { max($0, fraction($1)) }
        }
    }

    /// A gentle, dormant shape for when there are no real peaks — the web's placeholder curve.
    static func dormant(count: Int) -> [Double] {
        (0..<max(count, 0)).map { 0.22 + 0.18 * abs(sin(Double($0) / 3.1)) }
    }
}

/// What a Waveform says, in print and OUT LOUD.
nonisolated enum WaveformText {
    /// Whole seconds as `M:SS`; unknown as `--:--`.
    static func clock(_ seconds: Double?) -> String {
        // `Int(exactly:)`, because `Int(_:)` TRAPS on a finite value it cannot hold — and
        // `.greatestFiniteMagnitude` is a common "no end" sentinel.
        guard let seconds, seconds.isFinite, seconds >= 0, let whole = Int(exactly: seconds.rounded(.down)) else {
            return "--:--"
        }
        return "\(whole / 60):" + String(format: "%02d", whole % 60)
    }

    /// Elapsed and total BOTH round down, so at the end the two halves agree (`0:24 / 0:24`).
    static func elapsed(progress: Double, duration: TimeInterval) -> Double {
        // A time that went to a fraction and back can come home one ulp short (25 s → 24.999999999999996),
        // and rounding down would then show a whole second less. A millionth of a second puts it right.
        min(duration.rounded(.down), (WaveformMath.fraction(progress) * duration + 0.000_001).rounded(.down))
    }

    static func readout(progress: Double, duration: TimeInterval?) -> String {
        guard let duration = WaveformMath.valid(duration) else { return clock(nil) }
        return clock(elapsed(progress: progress, duration: duration)) + " / " + clock(duration)
    }

    /// The widest the readout gets for this duration — what holds its room.
    static func widestReadout(duration: TimeInterval?) -> String {
        let unknown = clock(nil)
        guard let duration = WaveformMath.valid(duration) else { return unknown }
        let total = clock(duration)
        return (total.count >= unknown.count ? total : unknown) + " / " + total
    }

    /// The name assistive tech hears. A blank label falls back, so a control is never nameless.
    static func name(_ label: String) -> String {
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? "Waveform" : label
    }

    /// Ten rows must not be ten buttons all called "Play": the button says which sound (as the web's does).
    static func toggleName(_ label: String, isPlaying: Bool) -> String {
        (isPlaying ? "Pause " : "Play ") + name(label)
    }

    /// What is said aloud when the status changes — with the name, so it is clear WHICH sound.
    static func announcement(_ label: String, source: Waveform.Source) -> String? {
        status(source).map { "\(name(label)): \($0)" }
    }

    /// The status line: `nil` when there is nothing to report.
    static func status(_ source: Waveform.Source) -> String? {
        switch source {
        case .loading: return "Loading waveform…"
        case .failed(let reason):
            let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return reason.isEmpty ? "Waveform unavailable" : reason
        case .peaks: return nil
        }
    }

    /// What the scrubber's value reads as: the status if there is one, else the time, else a percent.
    static func spokenValue(progress: Double, duration: TimeInterval?, source: Waveform.Source) -> String {
        if let status = status(source) { return status }
        // No peaks at all: the screen shows `--:--`, so a time must not be spoken either.
        if case .peaks(let peaks) = source, peaks.isEmpty { return "No waveform" }
        guard let duration = WaveformMath.valid(duration) else {
            return WaveformMath.fraction(progress).formatted(.percent.precision(.fractionLength(0)))
        }
        return clock(elapsed(progress: progress, duration: duration)) + " of " + clock(duration)
    }

    /// A compact wave is one image; its name carries the status the picture cannot.
    static func compactName(_ label: String, source: Waveform.Source) -> String {
        switch source {
        case .peaks: return name(label)
        case .loading: return "\(name(label)), loading waveform"
        // The consumer's own words stay as written: lowercasing turns "MP3" into a word.
        case .failed(let reason):
            let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(name(label)), " + (reason.isEmpty ? "waveform unavailable" : reason)
        }
    }
}
