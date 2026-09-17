import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let typography = CatalogEntry(
        name: "Typography",
        kind: .foundation,
        summary: "Six sizes, three families. .font(.trembus(.base, weight: .medium))",
        specimens: [
            Specimen("Scale", note: "TypeScale — xs 11 · sm 12 · base 14 · md 16 · lg 20 · xl 28") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(TypeScale.allCases.reversed(), id: \.self) { step in
                        MatrixRow("\(step.rawValue) · \(Int(step.size))") {
                            Text("Reveal state, afford action")
                                .font(.trembus(step, weight: step.size >= 20 ? .bold : .regular))
                                .foregroundStyle(.theme(.text))
                        }
                    }
                }
            },
            Specimen("Families", note: "FontFamily — sans for UI, mono for data, display for titles") {
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        MatrixRow(family.rawValue) {
                            Text("Acknowledge input 0123456789")
                                .font(.trembus(.md, family: family))
                                .foregroundStyle(.theme(.text))
                        }
                    }
                    MatrixRow("caps") {
                        Text("SECTION LABEL")
                            .font(.trembus(.xs, weight: .semibold))
                            .tracking(TypeScale.xs.tracking(.caps))
                            .foregroundStyle(.theme(.textDim))
                    }
                }
            },
        ])
}

struct TypographyEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.typography) }
}
