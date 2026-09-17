import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let input = CatalogEntry(
        name: "Input",
        kind: .component,
        summary: "A labeled, single-line text field. The whole box is the target, and errors speak up.",
        contract: ComponentContract(
            name: "Input",
            leadJob: .acknowledgeInput,
            revealState: JobSatisfaction(
                "reflects value, disabled, and invalid — a non-blank error turns the edge danger-toned and puts the message under the field; blank errors are ignored so a validator returning \"\" reads as valid.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a labeled, focusable text field on a raised fill with a strong edge; the whole box shows a text cursor, and clicking the label, the padding, or an icon focuses it.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "on focus the edge turns accent and a 2pt ring hugs it (danger-toned while invalid); a new error is announced to VoiceOver the moment it appears, and clears as soon as the text is valid.",
                specimen: "Interaction"),
            a11y: .init(role: "text field", keyboard: ["Tab", "Return"], focusRing: true),
            tokensUsed: [
                "ColorToken.surfaceRaised", "ColorToken.borderStrong", "ColorToken.accent", "ColorToken.focusRing",
                "Tone.danger", "Radius.md",
            ],
            buildsOn: ["ControlMetrics", "FieldShell", "FocusRing", "InteractionState"]),
        specimens: [
            Specimen("Default", note: "Input(\"Email\", text: $email, prompt: \"you@example.com\")") {
                VStack(alignment: .leading, spacing: Space.s5) {
                    Input("Email", text: .constant(""), prompt: "you@example.com")
                    Input(
                        "Project name", text: .constant("trembus-swift"),
                        description: "Shown in the sidebar and in URLs.", isRequired: true)
                    Input("Search", text: .constant(""), prompt: "Search components") {
                        Image(systemName: "magnifyingglass")
                    }
                    .labelsHidden()
                }
                .frame(width: 280)
            },
            Specimen(
                "States",
                note: "value × focus × validity × alignment — focus frozen with .interactionOverride(.focused)"
            ) {
                VStack(alignment: .leading, spacing: Space.s5) {
                    MatrixRow("empty") {
                        InputStateCells(text: "", error: nil)
                    }
                    MatrixRow("filled") {
                        InputStateCells(text: "ada@example.com", error: nil)
                    }
                    MatrixRow("invalid") {
                        InputStateCells(text: "ada@", error: "Enter a full email address.")
                    }
                    MatrixRow("extras") {
                        HStack(alignment: .top, spacing: Space.s5) {
                            Labeled("secure") {
                                Input("Password", text: .constant("hunter2hunter2"), isSecure: true).frame(width: 180)
                            }
                            Labeled("leading + trailing") {
                                Input(
                                    "Amount", text: .constant("1,250"),
                                    leading: { Image(systemName: "dollarsign") }, trailing: { Text("USD") }
                                )
                                .frame(width: 180)
                            }
                            Labeled("labelsHidden") {
                                Input("Filter", text: .constant(""), prompt: "Filter…").labelsHidden().frame(width: 180)
                            }
                        }
                    }
                    MatrixRow("aligned") {
                        HStack(alignment: .top, spacing: Space.s5) {
                            Labeled("trailing, empty") {
                                Input("Weight", text: .constant(""), prompt: "0.0", trailing: { Text("kg") })
                                    .multilineTextAlignment(.trailing).frame(width: 180)
                            }
                            Labeled("trailing, filled") {
                                Input("Weight", text: .constant("72.5"), prompt: "0.0", trailing: { Text("kg") })
                                    .multilineTextAlignment(.trailing).frame(width: 180)
                            }
                            Labeled("centered, empty") {
                                Input("Code", text: .constant(""), prompt: "000 000").labelsHidden()
                                    .multilineTextAlignment(.center).frame(width: 180)
                            }
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — type an address and press Return; fix it and watch the error leave") {
                InputPlayground()
            },
            Specimen("Sizes", note: "follows .controlSize(_:) — same heights as a Trembus button, so they line up") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach([ControlSize.small, .regular, .large], id: \.self) { size in
                        HStack(alignment: .bottom, spacing: Space.s3) {
                            Input("Name", text: .constant("Ada Lovelace")).labelsHidden().frame(width: 200)
                            Button("Save") {}.buttonStyle(.trembus)
                        }
                        .controlSize(size)
                    }
                }
            },
        ])
}

/// One row of the States matrix: the same field at rest, focused, and disabled.
private struct InputStateCells: View {
    let text: String
    let error: String?

    var body: some View {
        HStack(alignment: .top, spacing: Space.s5) {
            Labeled("rest") { cell }
            Labeled("focused") { cell.interactionOverride(.focused) }
            Labeled("disabled") { cell.disabled(true).interactionOverride(.disabled) }
        }
    }

    private var cell: some View {
        Input("Email", text: .constant(text), prompt: "you@example.com", error: error).frame(width: 180)
    }
}

private struct InputPlayground: View {
    @State private var email = ""
    @State private var hasSubmitted = false

    private var isValid: Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !parts[1].hasSuffix(".")
    }

    /// Nothing is "wrong" until you have tried — nagging at the first keystroke is rude.
    private var error: String? {
        guard hasSubmitted, !isValid else { return nil }
        return email.isEmpty ? "Email is required." : "Enter a full address, like ada@example.com."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Input(
                "Email", text: $email, prompt: "you@example.com", description: "Press Return to check it.",
                error: error, isRequired: true
            ) {
                Image(systemName: "envelope")
            }
            .onSubmit { hasSubmitted = true }
            .frame(width: 300)

            HStack(spacing: Space.s3) {
                Button("Check") { hasSubmitted = true }.buttonStyle(.trembus(.outline))
                Badge(
                    !hasSubmitted ? "Not checked" : isValid ? "Looks good" : "Needs fixing",
                    tone: !hasSubmitted ? .neutral : isValid ? .success : .danger, showsDot: true
                )
                .motion(Motion.calm(.base), value: isValid)
            }
        }
    }
}

struct InputEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.input) }
}
