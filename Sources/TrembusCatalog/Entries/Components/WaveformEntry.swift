import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let waveform = CatalogEntry(
        name: "Waveform",
        kind: .component,
        summary:
            "The shape of a sound, with a play button and a playhead you can drag. Draws plain data — you own the player.",
        contract: ComponentContract(
            name: "Waveform",
            leadJob: .revealState,
            revealState: JobSatisfaction(
                "draws the loudness of the sound as bars, the played part in full tone up to a playhead, beside a mono elapsed / total readout; playing FILLS the button — a shape change, not just a glyph swap; loading and failed draw the same dormant shape, say so in words (failed adds a glyph and a danger edge), and a change of status is announced with the name of the sound.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a real round play / pause button (Pressable) that names its sound — and can always pause one that is already playing — and the wave itself as the scrubber: its bars step up under the pointer, it takes keyboard focus like a slider, and assistive tech gets an adjustable value. The compact face is a picture only, by design.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "a drag keeps the playhead exactly under the pointer — no easing behind a drag — and letting go starts playback from there; arrow, Page, Home and End keys move the playhead without ever starting sound; the button presses in on a spring and swaps glyph and fill; a focus ring marks the wave.",
                specimen: "Interaction"),
            a11y: .init(
                role: "toggle button + slider (adjustable; label + elapsed of total)",
                keyboard: ["Space (play / pause)", "←/→ and ↑/↓ (5 s)", "Page Up/Down (10 s)", "Home", "End"],
                focusRing: true),
            tokensUsed: [
                "Tone", "ColorToken.surface", "ColorToken.surfaceRaised", "ColorToken.surfaceSunken",
                "ColorToken.surfaceHover", "ColorToken.border", "ColorToken.text", "ColorToken.textDim",
                "ColorToken.focusRing", "Radius.md", "Radius.sm", "Motion.calm", "Motion.spring",
            ],
            // Shape: the primitives + components this is made of. The gate checks it against the source.
            buildsOn: ["ControlMetrics", "FocusRing", "InteractionState", "Pressable", "Spinner"],
            // Form: what a Waveform IS, on any platform. Authored here — the web's AudioWaveform has no
            // `form:` yet, so there is nothing next door to copy or drift from. The day it has one, the gate
            // compares the two: `ContractTests.webNames` pairs this name with that one.
            form: ComponentForm(
                id: "form.waveform",
                revision: "r1",
                meaning:
                    "Shows the loudness of a sound over its whole length, and where playback is within it, so a listener can see the sound and move through it.",
                invariants: [
                    "The bars always span the whole sound, from its start to its end, whatever the width.",
                    "Played and unplayed are told apart by a playhead and a time readout, never by color alone.",
                    "A keyboard seek moves the playhead and never starts playback.",
                    "Loading and failed are said in words, and draw the same dormant shape, so the box never changes size.",
                    "The name of the sound is always present, to the eye or to assistive tech.",
                    "Time runs from left to right in every language; the timeline does not mirror.",
                ],
                prohibitions: [
                    "A waveform never starts sound by itself when it appears; only a press or a pointer release does.",
                    "The compact face never takes input; it is a picture of the sound.",
                ],
                variation: [
                    "Who owns the player: the web component holds its own audio element; the SwiftUI one is handed progress and playing as plain data.",
                    "How many bars are drawn: a fixed count stretched to fit on the web, as many as fit the width in SwiftUI.",
                    "The size of the button and the height of the wave follow the density of the platform.",
                ],
                relationships: [
                    .init(
                        .distinctFrom, "form.meter",
                        note:
                            "A meter says how much of something there is; a waveform says where you are in something that plays."
                    )
                ])),
        specimens: [
            Specimen(
                "Default", note: "Waveform(\"…\", source: .peaks(peaks), progress: $p, isPlaying: $on, duration: 24)"
            ) {
                WaveformStill(progress: 0.38)
            },
            Specimen(
                "States",
                note: "every state is plain data — idle · playing · loading · failed · frozen pointer states · compact"
            ) {
                HStack(alignment: .top, spacing: Space.s7) {
                    VStack(alignment: .leading, spacing: Space.s4) {
                        MatrixRow("idle") { WaveformStill(progress: 0) }
                        MatrixRow("playing") { WaveformStill(progress: 0.62, isPlaying: true) }
                        MatrixRow("loading") { WaveformStill(source: .loading) }
                        MatrixRow("failed") { WaveformStill(source: .failed("Can't read this file")) }
                        MatrixRow("no peaks") { WaveformStill(source: .peaks([])) }
                    }
                    VStack(alignment: .leading, spacing: Space.s4) {
                        MatrixRow("hover") { WaveformStill(progress: 0.38).interactionOverride(.hovered) }
                        MatrixRow("focused") { WaveformStill(progress: 0.38).interactionOverride(.focused) }
                        MatrixRow("disabled") { WaveformStill(progress: 0.38).interactionOverride(.disabled) }
                        MatrixRow("small") { WaveformStill(progress: 0.38, tone: .info).controlSize(.small) }
                        MatrixRow("large") { WaveformStill(progress: 0.38, tone: .success).controlSize(.large) }
                        MatrixRow("compact") {
                            HStack(spacing: Space.s4) {
                                Waveform(compact: "Take 3", source: .peaks(SampleSound.voice)).frame(width: 120)
                                Waveform(compact: "Take 3", source: .loading).frame(width: 80)
                                Waveform(compact: "Take 3", source: .failed("")).frame(width: 80)
                            }
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — drag the wave · press play · arrows seek, and never start sound") {
                WaveformPlayground()
            },
        ])
}

/// A made-up take: three phrases with breaths between them. Generated, so no audio file lives in the repo.
private enum SampleSound {
    static let voice: [Double] = (0..<240).map { index in
        let phrase = abs(sin(Double(index) / 240 * .pi * 3))
        let grain = 0.55 + 0.45 * abs(sin(Double(index) * 1.7) * cos(Double(index) * 0.37))
        return min(1, 0.06 + phrase * grain)
    }

    static let duration: TimeInterval = 24
}

/// One frozen Waveform. Every state on the sheet is this, fed different plain data.
private struct WaveformStill: View {
    var source: Waveform.Source = .peaks(SampleSound.voice)
    var progress = 0.0
    var isPlaying = false
    var tone: Tone = .accent

    var body: some View {
        Waveform(
            "Interview, take 3", source: source, progress: .constant(progress), isPlaying: .constant(isPlaying),
            duration: SampleSound.duration, tone: tone
        )
        .frame(width: 340)
    }
}

private struct WaveformPlayground: View {
    @State private var progress = 0.0
    @State private var isPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Waveform(
                "Interview, take 3", source: .peaks(SampleSound.voice), progress: $progress, isPlaying: $isPlaying,
                duration: SampleSound.duration
            )
            .frame(width: 340)
            Text("No sound here — a clock stands in for the player, as yours would.")
                .font(.trembus(.sm))
                .foregroundStyle(.theme(.textDim))
        }
        // The consumer's half of the bargain: watch `isPlaying`, move `progress`.
        .task(id: isPlaying) {
            guard isPlaying else { return }
            if progress >= 1 { progress = 0 }
            let tick = 1.0 / 30
            while progress < 1 {
                try? await Task.sleep(for: .seconds(tick))
                guard !Task.isCancelled else { return }
                progress = min(1, progress + tick / SampleSound.duration)
            }
            isPlaying = false
        }
    }
}

struct WaveformEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.waveform) }
}
