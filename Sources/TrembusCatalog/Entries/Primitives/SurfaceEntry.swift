import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let surface = CatalogEntry(
        name: "Surface",
        kind: .primitive,
        summary: "The box primitive: a themed backdrop with the right fill, edge, and lift for its level.",
        specimens: [
            Specimen(
                "Levels", note: "Surface(.raised) { … } — glass only shows in a live window; stills can't capture it"
            ) {
                HStack(alignment: .top, spacing: Space.s5) {
                    ForEach(SurfaceLevel.allCases, id: \.self) { level in
                        Surface(level) {
                            VStack(alignment: .leading, spacing: Space.s2) {
                                Text(level.rawValue)
                                    .font(.trembus(.base, weight: .semibold))
                                    .foregroundStyle(.theme(.text))
                                Text(level.caption)
                                    .font(.trembus(.xs))
                                    .foregroundStyle(.theme(.textDim))
                            }
                            .frame(width: 96, height: 48, alignment: .topLeading)
                        }
                    }
                }
                .padding(Space.s7)  // room for the overlay shadow: 32pt blur, 12pt drop
            },
            Specimen("Nesting", note: "a sunken well inside a raised card") {
                Surface(.raised) {
                    VStack(alignment: .leading, spacing: Space.s4) {
                        HStack {
                            Text("Deploy").font(.trembus(.md, weight: .semibold))
                                .foregroundStyle(.theme(.text))
                            Spacer()
                            Badge("Live", tone: .success, showsDot: true)
                        }
                        Surface(.sunken, radius: .md, padding: Space.s4) {
                            Text("main · 4f2a91c · 2 min ago")
                                .font(.trembus(.sm, family: .mono))
                                .foregroundStyle(.theme(.textDim))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(width: 280)
                }
                .padding(Space.s4)
            },
        ])
}

extension SurfaceLevel {
    fileprivate var caption: String {
        switch self {
        case .flat: "on the page"
        case .raised: "a card"
        case .sunken: "a well"
        case .overlay: "floats above"
        case .glass: "translucent"
        }
    }
}

struct SurfaceEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.surface) }
}
