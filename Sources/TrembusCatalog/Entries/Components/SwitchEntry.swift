import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let `switch` = CatalogEntry(
        name: "Switch",
        kind: .component,
        summary: "A style for SwiftUI's own Toggle: .toggleStyle(.trembus). The thumb stretches, then snaps home.",
        contract: ComponentContract(
            name: "Switch",
            leadJob: .acknowledgeInput,
            revealState: JobSatisfaction(
                "on and off differ by thumb POSITION as well as track tone, so state reads without color; disabled dims the whole row.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a track-and-thumb that looks slidable; the whole row including its label is the click target.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "while held the thumb stretches toward the other side — input is felt before it commits; on release it snaps across on a spring; track lights on hover; focus ring; Space toggles.",
                specimen: "Interaction"),
            a11y: .init(role: "switch", keyboard: ["Space"], focusRing: true),
            tokensUsed: [
                "Tone", "ColorToken.borderStrong", "ColorToken.focusRing", "Elevation.e1", "Motion.Springs.snap",
            ]),
        specimens: [
            Specimen("Default", note: "Toggle(\"…\", isOn: $on).toggleStyle(.trembus)") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    Toggle("Sync over cellular", isOn: .constant(true)).toggleStyle(.trembus)
                    Toggle("Send crash reports", isOn: .constant(false)).toggleStyle(.trembus)
                }
            },
            Specimen("States", note: "off / on × InteractionState") {
                VStack(alignment: .leading, spacing: Space.s5) {
                    MatrixRow("off") {
                        StateRow { Toggle("Label", isOn: .constant(false)).toggleStyle(.trembus) }
                    }
                    MatrixRow("on") {
                        StateRow { Toggle("Label", isOn: .constant(true)).toggleStyle(.trembus) }
                    }
                    MatrixRow("tones") {
                        HStack(spacing: Space.s5) {
                            ForEach(Tone.allCases, id: \.self) { tone in
                                Toggle(tone.rawValue, isOn: .constant(true))
                                    .toggleStyle(.trembus(tone: tone))
                            }
                        }
                    }
                    MatrixRow("sizes") {
                        HStack(spacing: Space.s6) {
                            Toggle("small", isOn: .constant(true)).toggleStyle(.trembus).controlSize(.small)
                            Toggle("regular", isOn: .constant(true)).toggleStyle(.trembus)
                            Toggle("large", isOn: .constant(true)).toggleStyle(.trembus).controlSize(.large)
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — press and HOLD to feel the stretch, then let go") {
                SwitchPlayground()
            },
        ])
}

private struct SwitchPlayground: View {
    @State private var isSyncing = true
    @State private var isArmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Toggle("Sync over cellular", isOn: $isSyncing).toggleStyle(.trembus)
            Toggle("Armed", isOn: $isArmed).toggleStyle(.trembus(tone: .danger))
            Toggle("Locked (disabled)", isOn: .constant(true)).toggleStyle(.trembus).disabled(true)
            Badge(isArmed ? "Armed" : "Safe", tone: isArmed ? .danger : .success, showsDot: true)
                .motion(Motion.calm(.base), value: isArmed)
        }
    }
}

struct SwitchEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.switch) }
}
