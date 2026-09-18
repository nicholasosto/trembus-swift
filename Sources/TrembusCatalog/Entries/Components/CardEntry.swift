import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let card = CatalogEntry(
        name: "Card",
        kind: .component,
        summary: "A raised surface that groups related content into one unit: header, body, footer.",
        contract: ComponentContract(
            name: "Card",
            leadJob: .revealState,
            revealState: JobSatisfaction(
                "groups related content into a single perceivable raised surface; hairlines separate header, body and footer, and an omitted section leaves no gap and no hairline.",
                specimen: "States"),
            affordAction: JobSatisfaction(
                "hosts action affordances — the footer slot lines controls up trailing; as a Button label with .trembusCard the whole card lifts on hover to say it can be pressed.",
                specimen: "Pressable"),
            acknowledgeInput: JobSatisfaction(
                "a plain card is static — its children answer input and it re-lays out around them; a pressable card lifts on hover, settles on press, and shows the focus ring.",
                specimen: "Interaction"),
            a11y: .init(role: "group — a button when styled .trembusCard", keyboard: ["Space"], focusRing: true),
            tokensUsed: [
                "ColorToken.surfaceRaised", "ColorToken.surfaceSunken", "ColorToken.border", "ColorToken.borderSoft",
                "ColorToken.borderStrong", "ColorToken.focusRing", "ColorToken.text",
                "Radius.lg", "Elevation.e1/e2", "Space.s3/s4/s6", "Motion.calm",
                "TypeScale.base",
            ],
            buildsOn: ["ElevationModifier", "FocusRing", "InteractionState", "Surface"],
            // Says the same thing, word for word, as the `form:` in the web's Card.contract.ts (read-only
            // from here). The gate reports any difference; it is settled by Nick, not by editing next door.
            form: ComponentForm(
                id: "form.card",
                revision: "r1",
                meaning:
                    "Groups related content into one perceivable unit, set apart from the page as a single raised surface.",
                invariants: [
                    "The body is always present; the header and the footer are optional.",
                    "An omitted section leaves no gap and no divider behind.",
                    "Sections are separated by a hairline, in the order header, body, footer.",
                    "Content is clipped to the rounded shape of the card.",
                    "Footer actions sit at the trailing edge.",
                ],
                prohibitions: [
                    "A card is never the base for another container; Dialog, Menu and Tooltip build on the surface directly.",
                    "A card never handles input itself; its children do.",
                ],
                variation: [
                    "How sections are supplied: compound children on the web, named slots in SwiftUI.",
                    "Padding and type size follow the density of the platform.",
                    "The optional hover lift for a card wrapped in a link or a button.",
                ],
                relationships: [
                    .init(
                        .distinctFrom, "form.dialog",
                        note: "A dialog interrupts and owns open and close; a card sits in the flow of the page.")
                ])),
        specimens: [
            Specimen("Default", note: "Card(\"Storage\") { … } footer: { … }") {
                Card("Storage") {
                    Meter(value: 0.64, label: "Used", showsValue: true)
                } footer: {
                    Button("Manage") {}.buttonStyle(.trembus(.outline))
                }
                .frame(width: CardSpecimen.width)
            },
            Specimen("States", note: "every combination of slots — a missing slot leaves no gap and no hairline") {
                HStack(alignment: .top, spacing: Space.s5) {
                    Card {
                        Text("Body only")
                    }
                    Card("Header") {
                        Text("Header + body")
                    }
                    Card {
                        Text("Body + footer")
                    } footer: {
                        Button("Done") {}.buttonStyle(.trembus(.outline))
                    }
                    Card {
                        Text("All three, with a custom header")
                    } header: {
                        HStack(spacing: Space.s3) {
                            Text("Deploy")
                            Badge("Live", tone: .success, showsDot: true)
                        }
                    } footer: {
                        Button("Done") {}.buttonStyle(.trembus(.outline))
                    }
                }
                .frame(width: CardSpecimen.width * 3)
            },
            Specimen("Pressable", note: "Button { } label: { Card… }.buttonStyle(.trembusCard) — frozen in every state")
            {
                StateRow {
                    Button {
                    } label: {
                        Card("Atlas") {
                            Meter(value: 0.4, label: "Progress", showsValue: true)
                        }
                        .frame(width: CardSpecimen.width * 0.6)
                    }
                    .buttonStyle(.trembusCard)
                }
            },
            Specimen(
                "Interaction",
                note:
                    "live — left: a plain card re-lays out around its children · right: a pressable card, hover and click it"
            ) {
                CardPlayground()
            },
        ])
}

private enum CardSpecimen {
    static let width: CGFloat = 280
}

private struct CardPlayground: View {
    @State private var showsDetail = false
    @State private var opened = 0

    var body: some View {
        HStack(alignment: .top, spacing: Space.s5) {
            plain
            // The whole card is the button: hover lifts it, press settles it, Tab rings it.
            Button {
                opened += 1
            } label: {
                Card("Atlas") {
                    Text("Opened \(opened)×")
                }
                .frame(width: CardSpecimen.width * 0.6)
            }
            .buttonStyle(.trembusCard)
        }
    }

    private var plain: some View {
        Card("Build") {
            VStack(alignment: .leading, spacing: Space.s4) {
                Meter(value: 0.4, label: "Progress", showsValue: true)
                if showsDetail {
                    Text("12 of 30 steps finished.")
                        .foregroundStyle(.theme(.textDim))
                }
            }
        } footer: {
            Button(showsDetail ? "Hide detail" : "Show detail") { showsDetail.toggle() }
                .buttonStyle(.trembus(.outline))
        }
        .frame(width: CardSpecimen.width)
    }
}

struct CardEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.card) }
}
