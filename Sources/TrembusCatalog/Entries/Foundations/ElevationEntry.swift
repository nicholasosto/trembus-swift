import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let elevation = CatalogEntry(
        name: "Elevation",
        kind: .foundation,
        summary: "Four levels of lift. Light stacks soft shadows; dark uses depth plus a hairline.",
        specimens: [
            Specimen("Levels", note: ".elevation(.e2, in: shape) — apply to the filled shape, not to text") {
                HStack(spacing: Space.s7) {
                    ForEach(Elevation.allCases, id: \.self) { level in
                        let shape = RoundedRectangle(cornerRadius: Radius.lg.value, style: .continuous)
                        Labeled("e\(level.rawValue)") {
                            shape
                                .fill(.theme(.surfaceRaised))
                                .elevation(level, in: shape)
                                .frame(width: 104, height: 68)
                        }
                    }
                }
                .padding(Space.s5)
            }
        ])
}

struct ElevationEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.elevation) }
}
