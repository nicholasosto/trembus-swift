import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let button = CatalogEntry(
        name: "Button",
        kind: .component,
        summary: "A style for SwiftUI's own Button: .buttonStyle(.trembus). Three variants, six tones.",
        contract: ComponentContract(
            name: "Button",
            leadJob: .affordAction,
            revealState: JobSatisfaction(
                "draws itself from one InteractionState (rest/hover/pressed/disabled); isLoading adds a spinner; the tone token sets the hue.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a real SwiftUI Button with a visible filled, edged, or hover-revealed affordance; destructive role reads as danger without being told.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "fill steps darker on hover then press; scales down on a no-bounce spring and releases with overshoot; focus ring for keyboard; Space activates.",
                specimen: "Interaction"),
            a11y: .init(role: "button", keyboard: ["Space"], focusRing: true),
            tokensUsed: ["Tone", "ColorToken.borderStrong", "ColorToken.focusRing", "Radius.md", "Space", "Motion"],
            buildsOn: ["ControlMetrics", "FocusRing", "InteractionState", "Spinner"]),
        specimens: [
            Specimen("Default", note: ".buttonStyle(.trembus) · .trembus(.outline) · .trembus(.ghost)") {
                HStack(spacing: Space.s4) {
                    Button("Save changes") {}.buttonStyle(.trembus)
                    Button("Preview") {}.buttonStyle(.trembus(.outline))
                    Button("Cancel") {}.buttonStyle(.trembus(.ghost))
                    Button("Delete", role: .destructive) {}.buttonStyle(.trembus)
                }
            },
            Specimen("States", note: "every state, frozen — variant × InteractionState, plus loading") {
                VStack(alignment: .leading, spacing: Space.s5) {
                    ForEach(TrembusButtonStyle.Variant.allCases, id: \.self) { variant in
                        MatrixRow(variant.rawValue) {
                            StateRow { Button("Button") {}.buttonStyle(.trembus(variant)) }
                        }
                    }
                    MatrixRow("loading") {
                        HStack(spacing: Space.s6) {
                            Button("Saving") {}.buttonStyle(.trembus(isLoading: true))
                            Button("Saving") {}.buttonStyle(.trembus(.outline, isLoading: true))
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — hover, press and hold, Tab to it, press Space") {
                ButtonPlayground()
            },
            Specimen("Tones", note: "the color-coded ontology — tone × variant") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(Tone.allCases, id: \.self) { tone in
                        MatrixRow(tone.rawValue) {
                            HStack(spacing: Space.s4) {
                                ForEach(TrembusButtonStyle.Variant.allCases, id: \.self) { variant in
                                    Button(variant.rawValue.capitalized) {}
                                        .buttonStyle(.trembus(variant, tone: tone))
                                        .frame(width: 84, alignment: .leading)
                                }
                            }
                        }
                    }
                }
            },
            Specimen("Sizes", note: "follows .controlSize(_:) — small 24 · regular 30 · large 38") {
                HStack(alignment: .center, spacing: Space.s5) {
                    Labeled("small") { Button("Button") {}.buttonStyle(.trembus).controlSize(.small) }
                    Labeled("regular") { Button("Button") {}.buttonStyle(.trembus).controlSize(.regular) }
                    Labeled("large") { Button("Button") {}.buttonStyle(.trembus).controlSize(.large) }
                    Labeled("fullWidth") {
                        Button("Continue") {}.buttonStyle(.trembus(fullWidth: true)).frame(width: 200)
                    }
                }
            },
        ])
}

private struct ButtonPlayground: View {
    @State private var count = 0
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(spacing: Space.s4) {
                Button("Count up") { count += 1 }.buttonStyle(.trembus)
                Button("Reset") { count = 0 }.buttonStyle(.trembus(.ghost, tone: .neutral))
                    .disabled(count == 0)
                Text("\(count)")
                    .font(.trembus(.lg, weight: .semibold, family: .mono))
                    .foregroundStyle(.theme(.text))
                    .contentTransition(.numericText(value: Double(count)))
                    .motion(Motion.spring(.snap), value: count)
            }
            Button(isSaving ? "Saving" : "Save (2 s)") {
                isSaving = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    isSaving = false
                }
            }
            .buttonStyle(.trembus(.outline, tone: .success, isLoading: isSaving))
        }
    }
}

struct ButtonEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.button) }
}
