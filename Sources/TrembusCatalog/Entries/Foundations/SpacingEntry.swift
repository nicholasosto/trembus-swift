import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let spacing = CatalogEntry(
        name: "Spacing",
        kind: .foundation,
        summary: "Space (4pt base) and Radius. Theme-invariant — same in every theme.",
        specimens: [
            Specimen("Space", note: "Space.s0 … Space.s8") {
                VStack(alignment: .leading, spacing: Space.s3) {
                    ForEach(Array(Space.steps.enumerated()), id: \.offset) { index, value in
                        MatrixRow("s\(index) · \(Int(value))") {
                            Capsule()
                                .fill(.tone(.accent))
                                .frame(width: max(value, 1), height: 10)
                        }
                    }
                }
            },
            Specimen("Radius", note: "Radius — md (5) is the Trembus kit button radius") {
                HStack(spacing: Space.s5) {
                    ForEach(Radius.allCases, id: \.self) { radius in
                        Labeled("\(radius.rawValue) · \(radius == .full ? "∞" : String(Int(radius.value)))") {
                            RoundedRectangle(cornerRadius: radius.value, style: .continuous)
                                .fill(.theme(.surfaceRaised))
                                .strokeBorder(.theme(.borderStrong), lineWidth: 1)
                                .frame(width: 64, height: 64)
                        }
                    }
                }
            },
        ])
}

struct SpacingEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.spacing) }
}
