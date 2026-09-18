import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let textarea = CatalogEntry(
        name: "Textarea",
        kind: .component,
        summary:
            "A labeled field for several lines of plain text. It grows with what you write, and Tab still moves on.",
        contract: ComponentContract(
            name: "Textarea",
            leadJob: .acknowledgeInput,
            revealState: JobSatisfaction(
                "reflects value, disabled, and invalid — a non-blank error turns the edge danger-toned and puts the message under the field; the box is as tall as its text, between the fewest and the most lines allowed.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a labeled, focusable box several lines tall on a raised fill with a strong edge; the whole box shows a text cursor, and clicking the label or the padding focuses it.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "on focus the edge turns accent and a 2pt ring hugs it (danger-toned while invalid); Return starts a new line and the box grows to fit it, then scrolls; Tab moves on; a new error is announced to VoiceOver the moment it appears.",
                specimen: "Interaction"),
            a11y: .init(role: "text area", keyboard: ["Tab", "Shift-Tab", "Return"], focusRing: true),
            tokensUsed: [
                "ColorToken.surfaceRaised", "ColorToken.surfaceSunken", "ColorToken.borderStrong", "ColorToken.accent",
                "ColorToken.focusRing", "ColorToken.text", "ColorToken.textFaint", "Tone.danger", "Radius.md",
            ],
            // Shape: the primitives + components this is made of. The gate checks it against the source.
            buildsOn: ["ControlMetrics", "FieldShell", "FocusRing", "InteractionState"],
            // Form: mirrored word for word from the web's Textarea.contract.ts. Change it THERE first.
            form: ComponentForm(
                id: "form.textarea",
                revision: "r1",
                meaning: "A labeled field for plain text that runs over several lines.",
                invariants: [
                    "A label names the field, even when the label is not shown.",
                    "The field is several lines tall even when it is empty.",
                    "Text wraps inside the field; it never runs off sideways.",
                    "Return starts a new line; it never submits.",
                    "Tab leaves the field; it never types a tab.",
                    "A placeholder shows only while the field is empty.",
                    "An error is shown in words under the field, turns the edge danger-toned, and is announced when it appears.",
                ],
                prohibitions: [
                    "Never used for a single line of text; that is an input.",
                    "Never styles the text; it holds plain text only.",
                ],
                variation: [
                    "How the height changes: a drag handle on the web; growing with the text up to a limit, then scrolling, in SwiftUI.",
                    "Padding and type size follow the density of the platform.",
                ],
                relationships: [
                    .init(
                        .distinctFrom, "form.input",
                        note:
                            "An input holds one line and Return submits it; a textarea holds many lines and Return starts a new one."
                    )
                ])),
        specimens: [
            Specimen(
                "Default", note: "Textarea(\"Notes\", text: $notes, prompt: \"Anything the next person should know\")"
            ) {
                VStack(alignment: .leading, spacing: Space.s5) {
                    Textarea("Notes", text: .constant(""), prompt: "Anything the next person should know")
                    Textarea(
                        "Description", text: .constant(TextareaSample.short),
                        description: "Shown at the top of the project page.", isRequired: true)
                }
                .frame(width: 320)
            },
            Specimen(
                "States",
                note: "value × focus × validity, then height — focus frozen with .interactionOverride(.focused)"
            ) {
                VStack(alignment: .leading, spacing: Space.s5) {
                    MatrixRow("empty") {
                        TextareaStateCells(text: "", error: nil)
                    }
                    MatrixRow("filled") {
                        TextareaStateCells(text: TextareaSample.short, error: nil)
                    }
                    MatrixRow("invalid") {
                        TextareaStateCells(text: "Too short.", error: "Write at least 20 characters.")
                    }
                    MatrixRow("height") {
                        HStack(alignment: .top, spacing: Space.s5) {
                            Labeled("grown to fit 6 lines") {
                                Textarea("Notes", text: .constant(TextareaSample.sixLines)).labelsHidden()
                                    .frame(width: 180)
                            }
                            Labeled("past the most: scrolls") {
                                Textarea("Notes", text: .constant(TextareaSample.long), lines: 2...5).labelsHidden()
                                    .frame(width: 180)
                            }
                            Labeled("lines: 2...2, labelsHidden") {
                                Textarea("Reply", text: .constant(""), prompt: "Reply…", lines: 2...2).labelsHidden()
                                    .frame(width: 180)
                            }
                        }
                    }
                }
            },
            Specimen("Interaction", note: "live — write, press Return (new line), press Tab (moves on), then Send") {
                TextareaPlayground()
            },
            Specimen("Sizes", note: "follows .controlSize(_:) — text lines up under an Input of the same size") {
                HStack(alignment: .top, spacing: Space.s5) {
                    ForEach([ControlSize.small, .regular, .large], id: \.self) { size in
                        VStack(alignment: .leading, spacing: Space.s3) {
                            Input("Title", text: .constant("Ada Lovelace")).labelsHidden()
                            Textarea("Notes", text: .constant("First programmer.\nSecond line."), lines: 3...6)
                                .labelsHidden()
                        }
                        .frame(width: 180)
                        .controlSize(size)
                    }
                }
            },
        ])
}

private enum TextareaSample {
    static let short = "A SwiftUI component library for macOS. Same tokens as the web."
    static let sixLines = "one\ntwo\nthree\nfour\nfive\nsix"
    static let long = (1...12).map { "Line \($0) of a long note." }.joined(separator: "\n")
}

/// One row of the States matrix: the same field at rest, focused, and disabled.
private struct TextareaStateCells: View {
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
        Textarea("Feedback", text: .constant(text), prompt: "What happened?", error: error, lines: 3...6)
            .frame(width: 180)
    }
}

private struct TextareaPlayground: View {
    @State private var feedback = ""
    @State private var subject = ""
    @State private var hasTriedToSend = false

    private var isLongEnough: Bool { feedback.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 }

    /// Nothing is "wrong" until you have tried — nagging at the first keystroke is rude.
    private var error: String? {
        guard hasTriedToSend, !isLongEnough else { return nil }
        return feedback.isEmpty ? "Feedback is required." : "Write at least 20 characters."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Textarea(
                "Feedback", text: $feedback, prompt: "What happened, and what did you expect?",
                description: "Return starts a new line. Tab moves to the next field.", error: error,
                isRequired: true, lines: 3...8)
            Input("Subject", text: $subject, prompt: "Tab lands here")

            HStack(spacing: Space.s3) {
                Button("Send") { hasTriedToSend = true }.buttonStyle(.trembus(.outline))
                Badge(
                    "\(feedback.count) characters",
                    tone: !hasTriedToSend ? .neutral : isLongEnough ? .success : .danger,
                    showsDot: true
                )
                .motion(Motion.calm(.base), value: isLongEnough)
            }
        }
        .frame(width: 320)
    }
}

struct TextareaEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.textarea) }
}
