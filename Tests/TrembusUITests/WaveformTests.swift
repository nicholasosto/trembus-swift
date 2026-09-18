import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

// Rendering in every theme and the contract are already covered for Waveform by RenderTests
// and ContractTests. This file is for its OWN LOGIC — and each invariant of its Form that a
// test (rather than an eye on the sheet) can hold.

@Suite("Waveform")
struct WaveformTests {
    // MARK: - Progress

    @Test func progressIsClampedAndNeverNotANumber() {
        #expect(WaveformMath.fraction(0.38) == 0.38)
        #expect(WaveformMath.fraction(-2) == 0)
        #expect(WaveformMath.fraction(7) == 1)
        #expect(WaveformMath.fraction(.nan) == 0)
        #expect(WaveformMath.fraction(.infinity) == 0)
    }

    @Test func aDurationThatIsNotKnownYetReadsAsAbsent() {
        #expect(WaveformMath.valid(24) == 24)
        for unknown: TimeInterval? in [nil, 0, -5, .nan, .infinity] {
            #expect(WaveformMath.valid(unknown) == nil)
        }
    }

    // MARK: - Seeking (Form: "A keyboard seek moves the playhead…")

    @Test func arrowsStepFiveSecondsAndPagesStepTen() {
        let seek = { WaveformMath.seek($0, from: 0.5, duration: 100) }
        #expect(seek(.forward) == 0.55)
        #expect(seek(.back) == 0.45)
        #expect(seek(.pageForward) == 0.6)
        #expect(seek(.pageBack) == 0.4)
        #expect(seek(.start) == 0)
        #expect(seek(.end) == 1)
    }

    @Test func aSeekNeverLeavesTheSound() {
        #expect(WaveformMath.seek(.back, from: 0.01, duration: 24) == 0)
        #expect(WaveformMath.seek(.pageForward, from: 0.99, duration: 24) == 1)
        // A short sound: one arrow is more than the whole thing.
        #expect(WaveformMath.seek(.forward, from: 0, duration: 2) == 1)
        #expect(WaveformMath.seek(.forward, from: .nan, duration: 24) > 0)
    }

    @Test func withNoDurationAnArrowIsStillAVisibleStep() {
        let step = WaveformMath.seek(.forward, from: 0, duration: nil)
        #expect(step > 0 && step < 0.2)
        #expect(WaveformMath.seek(.forward, from: 0, duration: 0) == step)  // 0 means "unknown", not "divide by it"
    }

    @Test func keysMapToMovesAndUpMeansForward() {
        #expect(WaveformMath.Move(.rightArrow) == .forward)
        #expect(WaveformMath.Move(.upArrow) == .forward)
        #expect(WaveformMath.Move(.leftArrow) == .back)
        #expect(WaveformMath.Move(.downArrow) == .back)
        #expect(WaveformMath.Move(.pageUp) == .pageForward)
        #expect(WaveformMath.Move(.pageDown) == .pageBack)
        #expect(WaveformMath.Move(.home) == .start)
        #expect(WaveformMath.Move(.end) == .end)
        #expect(WaveformMath.Move(.tab) == nil)  // Tab must stay free to leave the scrubber
        #expect(WaveformMath.Move(.space) == nil)  // Space plays; it is not a seek
    }

    // MARK: - Bars (Form: "The bars always span the whole sound…")

    @Test func barsAlwaysSpanTheWholeSound() {
        // A ramp: whatever the bar count, the first bar is the quiet start and the last is the loud end.
        let ramp = (0..<1000).map { Double($0) / 999 }
        for count in [1, 7, 96, 1000, 2500] {
            let bars = WaveformMath.bars(from: ramp, count: count)
            #expect(bars.count == count)
            #expect(bars.last == 1, "\(count) bars must reach the end of the sound")
            #expect(bars == bars.sorted(), "\(count) bars must keep the sound's order")
        }
        #expect(WaveformMath.bars(from: ramp, count: 2500).first == 0)
    }

    @Test func aSingleClapIsNeverAveragedAway() {
        var peaks = [Double](repeating: 0.05, count: 960)
        peaks[500] = 1
        let bars = WaveformMath.bars(from: peaks, count: 96)
        #expect(bars.max() == 1)
        #expect(bars.filter { $0 == 1 }.count == 1)
    }

    @Test func badPeaksAreClampedNotDrawnOffTheBox() {
        let bars = WaveformMath.bars(from: [-1, 0.5, 9, .nan, .infinity], count: 5)
        #expect(bars == [0, 0.5, 1, 0, 0])
    }

    @Test func noPeaksOrNoRoomDrawsNothingRatherThanCrashing() {
        #expect(WaveformMath.bars(from: [], count: 96).isEmpty)
        #expect(WaveformMath.bars(from: [0.5], count: 0).isEmpty)
        #expect(WaveformMath.bars(from: [0.5], count: 3) == [0.5, 0.5, 0.5])
        #expect(WaveformMath.dormant(count: 0).isEmpty)
        #expect(WaveformMath.dormant(count: -4).isEmpty)
    }

    @Test func theDormantShapeIsQuietAndTheSameEveryTime() {
        let dormant = WaveformMath.dormant(count: 96)
        #expect(dormant.count == 96)
        #expect(dormant.allSatisfy { $0 >= 0.2 && $0 <= 0.45 })
        #expect(dormant == WaveformMath.dormant(count: 96))
    }

    @Test func asManyBarsAsFitAndNeverFewerThanOne() {
        let metrics = ControlMetrics.waveform(.md)  // 2pt bars, 2pt gaps
        #expect(metrics.barCount(in: 200) == 50)
        #expect(metrics.barCount(in: 2) == 1)
        #expect(metrics.barCount(in: 0) == 1)
        #expect(metrics.barCount(in: -10) == 1)
        #expect(metrics.barCount(in: .nan) == 1)
    }

    @Test func theToggleLinesUpWithAButtonAtEverySize() {
        for step in [ControlMetrics.Step.sm, .md, .lg] {
            #expect(ControlMetrics.waveform(step).toggle == ControlMetrics.button(step).height)
        }
    }

    // MARK: - Words

    @Test func theClockIsMinutesAndTwoDigitSeconds() {
        #expect(WaveformText.clock(0) == "0:00")
        #expect(WaveformText.clock(9.99) == "0:09")
        #expect(WaveformText.clock(75) == "1:15")
        #expect(WaveformText.clock(3600) == "60:00")
        for unknown: Double? in [nil, -1, .nan, .infinity] {
            #expect(WaveformText.clock(unknown) == "--:--")
        }
    }

    @Test func elapsedAndTotalAgreeAtTheEnd() {
        // 24.6 s: both halves round DOWN, so the end reads 0:24 / 0:24 — never 0:25 / 0:24.
        #expect(WaveformText.readout(progress: 1, duration: 24.6) == "0:24 / 0:24")
        #expect(WaveformText.readout(progress: 0.38, duration: 24) == "0:09 / 0:24")
        #expect(WaveformText.readout(progress: 0.5, duration: nil) == "--:--")
        #expect(WaveformText.readout(progress: 0.5, duration: 0) == "--:--")
    }

    @Test func loadingAndFailedAreAlwaysSaidInWords() {
        #expect(WaveformText.status(.loading) == "Loading waveform…")
        #expect(WaveformText.status(.failed("Can't read this file")) == "Can't read this file")
        #expect(WaveformText.status(.failed("  \n")) == "Waveform unavailable")  // never a wordless red box
        #expect(WaveformText.status(.peaks([0.5])) == nil)
        #expect(WaveformText.status(.peaks([])) == nil)
    }

    @Test func theScrubberSpeaksTheStatusThenTheTimeThenAPercent() {
        #expect(WaveformText.spokenValue(progress: 0.38, duration: 24, source: .peaks([0.5])) == "0:09 of 0:24")
        // The percent is the system's, so it follows the reader's locale ("38%" · "38 %").
        #expect(
            WaveformText.spokenValue(progress: 0.38, duration: nil, source: .peaks([0.5]))
                == 0.38.formatted(.percent.precision(.fractionLength(0))))
        #expect(WaveformText.spokenValue(progress: 0.38, duration: 24, source: .loading) == "Loading waveform…")
    }

    @Test func aCompactWaveCarriesItsStatusInItsName() {
        #expect(WaveformText.compactName("Take 3", source: .peaks([0.5])) == "Take 3")
        #expect(WaveformText.compactName("Take 3", source: .loading) == "Take 3, loading waveform")
        #expect(WaveformText.compactName("Take 3", source: .failed("")) == "Take 3, waveform unavailable")
    }

    // MARK: - Review regressions (each was seen failing first)

    @Test func theReadoutNeverLosesASecondToRounding() {
        // Five → presses on a 30 s sound is 25 s. As a fraction and back it is 24.999999999999996.
        var progress = 0.0
        for _ in 0..<5 { progress = WaveformMath.seek(.forward, from: progress, duration: 30) }
        #expect(WaveformText.readout(progress: progress, duration: 30) == "0:25 / 0:30")
        #expect(WaveformText.readout(progress: 15.0 / 22, duration: 22) == "0:15 / 0:22")
        #expect(WaveformText.readout(progress: 5 / 19.7, duration: 19.7) == "0:05 / 0:19")
        // …and the nudge that fixes it must not push a real 0:24.9 up to 0:25.
        #expect(WaveformText.readout(progress: 24.9 / 30, duration: 30) == "0:24 / 0:30")
    }

    @Test func anEmptyWaveSpeaksNoTimeTheScreenDoesNotShow() {
        let spoken = WaveformText.spokenValue(progress: 0.5, duration: 24, source: .peaks([]))
        #expect(!spoken.contains("of"), "the screen shows --:-- here; VoiceOver said \(spoken.debugDescription)")
    }

    @Test func aCompactNameKeepsTheConsumersWordsAsWritten() {
        #expect(WaveformText.compactName("Take 3", source: .failed("Can't read MP3")) == "Take 3, Can't read MP3")
        #expect(WaveformText.compactName("Take 3", source: .failed("Not found (404)")) == "Take 3, Not found (404)")
    }

    @Test func aHugeDurationReadsAsUnknownInsteadOfCrashing() {
        // `.greatestFiniteMagnitude` is a common "no end" sentinel — and `Int(_:)` TRAPS on it.
        #expect(WaveformText.clock(.greatestFiniteMagnitude) == "--:--")
        #expect(WaveformText.readout(progress: 0.5, duration: .greatestFiniteMagnitude).hasSuffix("--:--"))
        #expect(ControlMetrics.waveform(.md).barCount(in: .greatestFiniteMagnitude) >= 1)
    }

    @Test func heldDownSpaceTogglesOnceNotAtTheKeyRepeatRate() {
        #expect(WaveformMath.togglesPlayback(.space, isRepeat: false))
        #expect(!WaveformMath.togglesPlayback(.space, isRepeat: true))
        #expect(!WaveformMath.togglesPlayback(.rightArrow, isRepeat: false))  // a seek never starts sound
    }

    @Test func noAnimationMeansNoneEvenUnderReduceMotion() {
        // A drag must sit under the pointer. A zero-length animation is NOT none: Reduce Motion swaps it for a fade.
        #expect(ReducedMotion.resolve(nil, reduceMotion: true) == nil)
        #expect(ReducedMotion.resolve(nil, reduceMotion: false) == nil)
        #expect(ReducedMotion.resolve(Motion.calm(), reduceMotion: true) == Motion.reduced)
        #expect(ReducedMotion.resolve(Motion.calm(), reduceMotion: false) == Motion.calm())
    }

    @Test func theReadoutHoldsRoomForItsWidestSelf() {
        for duration: TimeInterval? in [nil, 24, 599, 600, 3725] {
            let widest = WaveformText.widestReadout(duration: duration).count
            for progress in stride(from: 0.0, through: 1.0, by: 0.05) {
                #expect(WaveformText.readout(progress: progress, duration: duration).count <= widest)
            }
            #expect(
                WaveformText.readout(progress: 0, duration: nil).count <= widest, "--:-- while loading must fit too")
        }
    }

    @Test func everyControlSaysWhichSoundAndIsNeverNameless() {
        #expect(WaveformText.toggleName("Take 3", isPlaying: false) == "Play Take 3")
        #expect(WaveformText.toggleName("Take 3", isPlaying: true) == "Pause Take 3")
        #expect(WaveformText.name("  ") == "Waveform")
        #expect(WaveformText.announcement("Take 3", source: .loading) == "Take 3: Loading waveform…")
        #expect(WaveformText.announcement("Take 3", source: .peaks([0.5])) == nil)
    }

    // MARK: - Readiness

    @Test func onlyRealPeaksCanBePlayedOrScrubbed() {
        func waveform(_ source: Waveform.Source) -> Waveform {
            Waveform("Take 3", source: source, progress: .constant(0), isPlaying: .constant(false))
        }
        #expect(waveform(.peaks([0.2, 0.8])).isReady)
        #expect(!waveform(.peaks([])).isReady)
        #expect(!waveform(.loading).isReady)
        #expect(!waveform(.failed("nope")).isReady)
    }
}
