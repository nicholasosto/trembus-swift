import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let badge = CatalogEntry(
        name: "Badge",
        kind: .component,
        summary: "A small status label. Tone says what kind of state; the word says which.",
        contract: ComponentContract(
            name: "Badge",
            leadJob: .revealState,
            revealState: JobSatisfaction(
                "maps a status to the six-tone ontology via tokens; tone is never the only signal — there is always a word, and the dot becomes a per-tone glyph under Differentiate Without Color.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "non-interactive by design — it reports state; the optional leading dot reinforces that it is a live status, not a button.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "takes no input itself; when the state it reports changes, it re-tones in place, and its label plus tone are exposed to VoiceOver as label and value.",
                specimen: "Interaction"),
            a11y: .init(focusRing: false),
            tokensUsed: ["Tone", "Radius.full", "Space", "TypeScale.xs/sm"],
            buildsOn: ["ControlMetrics"]),
        specimens: [
            Specimen("Default", note: "Badge(\"Live\", tone: .success, showsDot: true)") {
                HStack(spacing: Space.s4) {
                    Badge("Draft")
                    Badge("Live", tone: .success, showsDot: true)
                    Badge("3 failed", tone: .danger, variant: .solid)
                    Badge("Beta", tone: .accent, variant: .outline)
                }
            },
            Specimen("States", note: "tone × variant — every state it can reveal") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(Badge.Variant.allCases, id: \.self) { variant in
                        MatrixRow(variant.rawValue) {
                            HStack(spacing: Space.s3) {
                                ForEach(Tone.allCases, id: \.self) { tone in
                                    Badge(tone.rawValue.capitalized, tone: tone, variant: variant, showsDot: true)
                                }
                            }
                        }
                    }
                    MatrixRow("small") {
                        HStack(spacing: Space.s3) {
                            ForEach(Tone.allCases, id: \.self) { tone in
                                Badge(tone.rawValue.capitalized, tone: tone)
                            }
                        }
                        .controlSize(.small)
                    }
                }
            },
            Specimen("Interaction", note: "live — the badge re-tones as the state it reports changes") {
                BadgePlayground()
            },
        ])
}

private struct BadgePlayground: View {
    private static let stages: [(String, Tone)] = [
        ("Queued", .neutral), ("Building", .info), ("Deployed", .success), ("Degraded", .warning),
        ("Down", .danger),
    ]
    @State private var index = 0

    var body: some View {
        let stage = Self.stages[index]
        HStack(spacing: Space.s4) {
            Button("Next state") { index = (index + 1) % Self.stages.count }
                .buttonStyle(.trembus(.outline))
            Badge(stage.0, tone: stage.1, showsDot: true)
                .motion(Motion.calm(.base), value: index)
        }
    }
}

struct BadgeEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.badge) }
}
