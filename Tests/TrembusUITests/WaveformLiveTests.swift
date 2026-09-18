import AppKit
import Combine
import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

/// What the Form promises about a LIVE waveform: what a pointer does to it, and what it must never do
/// by itself. These need a real (never shown) window — see `LiveWindowTests`.
extension LiveWindowTests {
    @Suite("Waveform — live")
    struct WaveformLiveTests {
        final class Box: ObservableObject {
            @Published var progress = 0.0
            @Published var isPlaying = false
            /// Set to swap what there is to draw while the view is live.
            @Published var source: Waveform.Source?
        }

        struct Harness: View {
            static let width: CGFloat = 400
            static let margin: CGFloat = 20

            @ObservedObject var box: Box
            var source: Waveform.Source = .peaks((0..<200).map { 0.2 + 0.6 * abs(sin(Double($0) / 9)) })
            var playsOnRelease = true
            var isDisabled = false

            var body: some View {
                Waveform(
                    "Take 3", source: box.source ?? source, progress: $box.progress, isPlaying: $box.isPlaying,
                    duration: 100,
                    playsOnRelease: playsOnRelease
                )
                .disabled(isDisabled)
                .frame(width: Self.width)
                .padding(Self.margin)
                .background(Color.white)
                .trembusTheme(.light)
            }
        }

        /// A point inside the wave, in WINDOW coordinates (origin bottom-left). The wave is the bottom row of
        /// the box: margin + box padding + half the wave's height up from the bottom.
        private func pointOnWave(x: CGFloat) -> NSPoint {
            let metrics = ControlMetrics.waveform(.md)
            return NSPoint(x: x, y: Harness.margin + Space.s4 + metrics.waveHeight / 2)
        }

        /// Where the wave starts: margin + box padding + the toggle + the gap after it.
        private var waveLeft: CGFloat {
            Harness.margin + Space.s4 + ControlMetrics.waveform(.md).toggle + Space.s4
        }

        @Test func nothingPlaysAndNothingMovesUntilSomeoneActs() {
            let box = Box()
            let (window, _) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            LiveWindowTests.settle(0.5)
            #expect(!box.isPlaying, "the Form: a waveform never starts sound by itself when it appears")
            #expect(box.progress == 0)
        }

        @Test func aClickOnTheWaveSeeksThereAndStartsPlayback() {
            let box = Box()
            let (window, _) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }

            LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 60))
            LiveWindowTests.settle()
            let early = box.progress
            #expect(early > 0.05 && early < 0.6, "a click 60pt into the wave should seek a little way in, got \(early)")
            #expect(box.isPlaying, "letting go of the wave starts playback from there")

            box.isPlaying = false
            LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 160))
            LiveWindowTests.settle()
            #expect(box.progress > early, "a click further right must seek further: \(box.progress) vs \(early)")
        }

        @Test func aClickAtTheVeryStartOfTheWaveIsTheStartOfTheSound() {
            let box = Box()
            box.progress = 0.5
            let (window, _) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 1))
            LiveWindowTests.settle()
            #expect(box.progress < 0.02, "the first point of the wave is 0:00, got \(box.progress)")
        }

        @Test func withPlaysOnSeekOffAClickOnlyMovesThePlayhead() {
            let box = Box()
            let (window, _) = LiveWindowTests.mount(Harness(box: box, playsOnRelease: false))
            defer { LiveWindowTests.unmount(window) }
            LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 100))
            LiveWindowTests.settle()
            #expect(box.progress > 0)
            #expect(!box.isPlaying)
        }

        @Test func aWaveWithNothingToPlayIgnoresThePointer() {
            for source in [Waveform.Source.loading, .failed("Can't read this file"), .peaks([])] {
                let box = Box()
                let (window, _) = LiveWindowTests.mount(Harness(box: box, source: source))
                LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 100))
                LiveWindowTests.click(window, at: pointOnWave(x: Harness.margin + Space.s4 + 15))  // the play button
                LiveWindowTests.settle()
                #expect(box.progress == 0, "\(source): a click must not seek through a wave that is not there")
                #expect(!box.isPlaying, "\(source): nothing to play, so nothing may start")
                LiveWindowTests.unmount(window)
            }
        }

        @Test func aDisabledWaveformIgnoresThePointer() {
            let box = Box()
            let (window, _) = LiveWindowTests.mount(Harness(box: box, isDisabled: true))
            defer { LiveWindowTests.unmount(window) }
            LiveWindowTests.click(window, at: pointOnWave(x: waveLeft + 100))
            LiveWindowTests.click(window, at: pointOnWave(x: Harness.margin + Space.s4 + 15))
            LiveWindowTests.settle()
            #expect(box.progress == 0)
            #expect(!box.isPlaying)
        }

        @Test func thePlayButtonTogglesPlaybackAndNeverMovesThePlayhead() {
            let box = Box()
            box.progress = 0.3
            let (window, _) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }
            let button = pointOnWave(x: Harness.margin + Space.s4 + 15)

            LiveWindowTests.click(window, at: button)
            LiveWindowTests.settle()
            #expect(box.isPlaying)
            LiveWindowTests.click(window, at: button)
            LiveWindowTests.settle()
            #expect(!box.isPlaying)
            #expect(box.progress == 0.3)
        }

        /// Half a click, the way the window server would send it.
        private func mouse(_ type: NSEvent.EventType, _ window: NSWindow, at point: NSPoint) {
            if let event = NSEvent.mouseEvent(
                with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            {
                window.sendEvent(event)
            }
        }

        /// Found in review: the button was dead whenever the wave was not ready — so a sound that was ALREADY
        /// playing while its peaks loaded (or after they failed) could not be stopped.
        @Test func aSoundThatIsPlayingCanAlwaysBePaused() {
            for source in [Waveform.Source.loading, .failed("Can't read this file")] {
                let box = Box()
                box.isPlaying = true
                let (window, _) = LiveWindowTests.mount(Harness(box: box, source: source))
                LiveWindowTests.click(window, at: pointOnWave(x: Harness.margin + Space.s4 + 15))
                LiveWindowTests.settle()
                #expect(!box.isPlaying, "\(source): the pause button did nothing")
                LiveWindowTests.unmount(window)
            }
        }

        /// Found in review: a drag cut short (the next track starts loading while the mouse is still down) must
        /// not start playback on a wave that is no longer there.
        @Test func aDragCutShortNeverStartsPlayback() {
            let box = Box()
            let (window, _) = LiveWindowTests.mount(Harness(box: box))
            defer { LiveWindowTests.unmount(window) }

            mouse(.leftMouseDown, window, at: pointOnWave(x: waveLeft + 100))
            LiveWindowTests.settle(0.1)
            #expect(box.progress > 0, "precondition: the drag began")
            box.source = .loading
            LiveWindowTests.settle(0.1)
            mouse(.leftMouseUp, window, at: pointOnWave(x: waveLeft + 100))
            LiveWindowTests.settle()
            #expect(!box.isPlaying, "letting go over a wave that is still loading started playback")
        }

        @Test func theBoxIsTheSameSizeWhateverThereIsToDraw() {
            func size(_ source: Waveform.Source) -> CGSize {
                NSHostingView(rootView: Harness(box: Box(), source: source)).fittingSize
            }
            let ready = size(.peaks([0.2, 0.9, 0.4]))
            #expect(size(.loading) == ready, "the Form: loading must not change the size of the box")
            #expect(
                size(.failed("Can't read this file")) == ready, "the Form: failed must not change the size of the box")
            #expect(size(.peaks([])) == ready)
        }
    }
}
