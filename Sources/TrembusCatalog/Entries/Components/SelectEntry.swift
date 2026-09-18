import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let select = CatalogEntry(
        name: "Select",
        kind: .component,
        summary:
            "A labeled field for choosing one option from a closed list. A Trembus box when closed; the Mac's own pop-up menu when open.",
        contract: ComponentContract(
            name: "Select",
            leadJob: .acknowledgeInput,
            revealState: JobSatisfaction(
                "the closed field shows the chosen option in words, or the prompt, fainter, while nothing is chosen; it reflects disabled and invalid — a non-blank error turns the edge danger-toned and puts the message under the field; in the open list the chosen option is checked and an option that cannot be chosen is dimmed.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "a labeled box on a raised fill with a strong edge, like an Input, with up-and-down chevrons at the trailing edge that say it opens a list; the whole box is the target, and it opens on mouse-down as every Mac pop-up does.",
                specimen: "Default"),
            acknowledgeInput: JobSatisfaction(
                "pressing it opens the list over the field with the chosen option under the pointer; choosing closes the list and the field says the new words at once; on keyboard focus the edge turns accent and a 2pt ring hugs it (danger-toned while invalid); a new error is announced to VoiceOver the moment it appears.",
                specimen: "Interaction"),
            a11y: .init(
                role: "pop up button", keyboard: ["Tab", "Space", "Up Arrow", "Down Arrow", "Return", "Escape"],
                focusRing: true),
            tokensUsed: [
                "ColorToken.surfaceRaised", "ColorToken.surfaceSunken", "ColorToken.borderStrong", "ColorToken.accent",
                "ColorToken.focusRing", "ColorToken.text", "ColorToken.textDim", "ColorToken.textFaint", "Tone.danger",
                "Radius.md",
            ],
            // Shape: the primitives + components this is made of. The gate checks it against the source.
            buildsOn: ["ControlMetrics", "FieldShell", "FocusRing", "InteractionState", "Pressable"],
            // Form: authored here — the web's Select.contract.ts has none yet. If it gains one, the gate
            // compares the two and reports any difference.
            form: ComponentForm(
                id: "form.select",
                revision: "r1",
                meaning: "A labeled field for choosing exactly one option from a closed list.",
                invariants: [
                    "A label names the field, even when the label is not shown.",
                    "The closed field shows the chosen option in words.",
                    "While nothing is chosen the field shows a placeholder, and the placeholder can never be chosen.",
                    "A mark at the trailing edge says the field opens a list.",
                    "Activating the field shows every option; choosing one closes the list and updates the field.",
                    "An option that cannot be chosen stays in the list, dimmed.",
                    "An error is shown in words under the field, turns the edge danger-toned, and is announced when it appears.",
                ],
                prohibitions: [
                    "Never used for free text; that is an input.",
                    "Never used to choose several options at once.",
                    "Never used to run commands; its options are values, not actions.",
                ],
                variation: [
                    "The open list belongs to the platform: the browser's option list on the web; a native pop-up menu in SwiftUI.",
                    "The mark: a single down chevron on the web; the Mac's up-and-down chevrons in SwiftUI.",
                    "Height, padding and type size follow the density of the platform.",
                ],
                relationships: [
                    .init(
                        .distinctFrom, "form.input",
                        note: "An input takes any text; a select only takes one of the options it lists.")
                ])),
        specimens: [
            Specimen(
                "Default", note: "Select(\"Role\", selection: $role, options: roles, prompt: \"Choose a role\")"
            ) {
                VStack(alignment: .leading, spacing: Space.s5) {
                    Select("Role", selection: .constant(nil), options: SelectSample.roles, prompt: "Choose a role")
                    Select(
                        "Default branch", selection: .constant("main"), options: SelectSample.branches,
                        description: "New pull requests open against it.", isRequired: true)
                    Select("Sort by", selection: .constant("Newest first"), options: SelectSample.sorts)
                        .labelsHidden()
                }
                .frame(width: 280)
            },
            Specimen(
                "States",
                note:
                    "value × focus × validity — focus frozen with .interactionOverride(.focused). The open list is the Mac's own menu: see it live."
            ) {
                VStack(alignment: .leading, spacing: Space.s5) {
                    MatrixRow("nothing chosen") {
                        SelectStateCells(role: nil, error: nil)
                    }
                    MatrixRow("chosen") {
                        SelectStateCells(role: .editor, error: nil)
                    }
                    MatrixRow("invalid") {
                        SelectStateCells(role: nil, error: "Choose a role.")
                    }
                    MatrixRow("extras") {
                        HStack(alignment: .top, spacing: Space.s5) {
                            Labeled("long option: cut at the end") {
                                Select(
                                    "Branch", selection: .constant(SelectSample.longBranch),
                                    options: SelectSample.branches
                                )
                                .frame(width: 180)
                            }
                            Labeled("a value the list lacks: the prompt") {
                                Select(
                                    "Branch", selection: .constant("gone"), options: SelectSample.branches,
                                    prompt: "Choose a branch"
                                )
                                .frame(width: 180)
                            }
                            Labeled("labelsHidden") {
                                Select("Sort by", selection: .constant("Newest first"), options: SelectSample.sorts)
                                    .labelsHidden().frame(width: 180)
                            }
                        }
                    }
                }
            },
            Specimen(
                "Interaction",
                note:
                    "live — press and hold, drag to an option, let go. Owner is dimmed. Then Invite with nothing chosen"
            ) {
                SelectPlayground()
            },
            Specimen("Sizes", note: "follows .controlSize(_:) — same heights as an Input and a Trembus button") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach([ControlSize.small, .regular, .large], id: \.self) { size in
                        HStack(alignment: .bottom, spacing: Space.s3) {
                            Input("Name", text: .constant("Ada Lovelace")).labelsHidden().frame(width: 160)
                            Select("Role", selection: .constant(SelectSample.Role.editor), options: SelectSample.roles)
                                .labelsHidden().frame(width: 140)
                            Button("Invite") {}.buttonStyle(.trembus)
                        }
                        .controlSize(size)
                    }
                }
            },
        ])
}

private enum SelectSample {
    enum Role: String, CaseIterable {
        case owner, admin, editor, viewer
    }

    /// Owner stays in the list, dimmed: there is one already, and you cannot invite another.
    static let roles = Role.allCases.map { SelectOption($0.rawValue.capitalized, value: $0, isEnabled: $0 != .owner) }

    static let longBranch = "feature/select-with-a-very-long-branch-name"
    static let branches = ["main", "develop", "release/2.0", longBranch].map { SelectOption($0, value: $0) }
    static let sorts = ["Newest first", "Oldest first", "Name"].map { SelectOption($0, value: $0) }
}

/// One row of the States matrix: the same field at rest, focused, and disabled.
private struct SelectStateCells: View {
    let role: SelectSample.Role?
    let error: String?

    var body: some View {
        HStack(alignment: .top, spacing: Space.s5) {
            Labeled("rest") { cell }
            Labeled("focused") { cell.interactionOverride(.focused) }
            Labeled("disabled") { cell.disabled(true).interactionOverride(.disabled) }
        }
    }

    private var cell: some View {
        Select("Role", selection: .constant(role), options: SelectSample.roles, prompt: "Choose a role", error: error)
            .frame(width: 180)
    }
}

private struct SelectPlayground: View {
    @State private var role: SelectSample.Role?
    @State private var sort = "Newest first"
    @State private var hasTriedToInvite = false

    /// Nothing is "wrong" until you have tried — nagging before the first choice is rude.
    private var error: String? {
        hasTriedToInvite && role == nil ? "Choose a role before inviting." : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Select(
                "Role", selection: $role, options: SelectSample.roles, prompt: "Choose a role",
                description: "Decides what they can change.", error: error, isRequired: true)
            Select("Sort by", selection: $sort, options: SelectSample.sorts)

            HStack(spacing: Space.s3) {
                Button("Invite") { hasTriedToInvite = true }.buttonStyle(.trembus(.outline))
                Badge(
                    role.map { "Invites as \($0.rawValue)" } ?? "No role yet",
                    tone: role != nil ? .success : hasTriedToInvite ? .danger : .neutral, showsDot: true
                )
                .motion(Motion.calm(.base), value: role)
            }
        }
        .frame(width: 300)
    }
}

struct SelectEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.select) }
}
