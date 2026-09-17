import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let meter = CatalogEntry(
        name: "Meter",
        kind: .component,
        summary: "A fill bar: how much of something, at a glance. Can pick its own tone from the value.",
        contract: ComponentContract(
            name: "Meter",
            leadJob: .revealState,
            revealState: JobSatisfaction(
                "fill length is the value; with .levels the bar chooses danger / warning / success from the value itself; optional label and tabular percent.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "non-interactive by design — a read-only gauge; its sunken track reads as a channel being filled, not a slider to grab.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "takes no input itself; when its value changes the fill glides on the calm curve and the percent ticks numerically, so the change is seen, not just the result.",
                specimen: "Interaction"),
            a11y: .init(role: "meter (label + percent value)", focusRing: false),
            tokensUsed: ["Tone", "ColorToken.surfaceSunken", "ColorToken.borderSoft", "Radius.full", "Motion.calm"]),
        specimens: [
            Specimen("Default", note: "Meter(value: 0.64, label: \"Storage\", showsValue: true)") {
                VStack(alignment: .leading, spacing: Space.s5) {
                    Meter(value: 0.64)
                    Meter(value: 0.64, label: "Storage", showsValue: true)
                    Meter(value: 42, in: 0...60, tone: .fixed(.info), label: "Fuel (42 of 60 L)", showsValue: true)
                }
                .frame(width: 280)
            },
            Specimen("States", note: "empty → full, and .levels(dangerBelow:warningBelow:) choosing its own tone") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach([0, 0.02, 0.5, 1.0], id: \.self) { value in
                        MatrixRow(value.formatted(.percent)) {
                            Meter(value: value, tone: .fixed(.accent)).frame(width: 220)
                        }
                    }
                    ForEach([0.08, 0.2, 0.9], id: \.self) { value in
                        MatrixRow("levels") {
                            Meter(
                                value: value, tone: .levels(dangerBelow: 0.1, warningBelow: 0.25),
                                label: "Battery", showsValue: true
                            )
                            .frame(width: 220)
                        }
                    }
                    MatrixRow("sizes") {
                        HStack(spacing: Space.s5) {
                            Meter(value: 0.6).controlSize(.small).frame(width: 90)
                            Meter(value: 0.6).frame(width: 90)
                            Meter(value: 0.6).controlSize(.large).frame(width: 90)
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — drain it and watch the tone change itself") {
                MeterPlayground()
            },
        ])
}

private struct MeterPlayground: View {
    @State private var level = 0.72

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Meter(
                value: level, tone: .levels(dangerBelow: 0.1, warningBelow: 0.25), label: "Battery",
                showsValue: true
            )
            .frame(width: 280)
            HStack(spacing: Space.s3) {
                Button("− 20%") { level = max(level - 0.2, 0) }.buttonStyle(.trembus(.outline))
                Button("+ 20%") { level = min(level + 0.2, 1) }.buttonStyle(.trembus(.outline))
                Button("Charge") { level = 1 }.buttonStyle(.trembus(.ghost, tone: .success))
            }
            .controlSize(.small)
        }
    }
}

struct MeterEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.meter) }
}
