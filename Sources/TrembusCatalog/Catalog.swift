import SwiftUI
import TrembusTokens
import TrembusUI

/// The registry. ONE list feeds four things:
///
///     Catalog.entries ─┬─▶ TrembusGallery   live app — hover, press, feel it
///                      ├─▶ TrembusSnap      PNG sheets — see every theme at once
///                      ├─▶ Xcode previews   canvas, hot reload
///                      └─▶ tests            contract gate + "every specimen renders"
public enum Catalog {
    public static let entries: [CatalogEntry] = [
        // Foundations
        .colors,
        .typography,
        .spacing,
        .elevation,
        .motion,
        // Primitives
        .surface,
        .pressable,
        // Components
        .badge,
        .button,
        .meter,
        .switch,
        .input,
        .card,
        .textarea,
        // scaffold:entries — `make new` inserts new components above this line
        // Examples
        .projectSettings,
    ]

    public static func entries(of kind: CatalogEntry.Kind) -> [CatalogEntry] {
        entries.filter { $0.kind == kind }
    }

    /// Harmonics: what to re-look at when `name` (a primitive file or a component) changes — every
    /// component that builds on it and every example that composes it, walked backwards at most
    /// `hops` steps. Review candidates, not proof.
    public static func neighbors(of name: String, hops: Int = 2) -> [(name: String, distance: Int)] {
        var found: [(name: String, distance: Int)] = []
        guard hops > 0 else { return found }
        var frontier = [name]
        for distance in 1...hops {
            let next = entries.filter { entry in
                entry.madeOf.contains { target in
                    frontier.contains { $0.caseInsensitiveCompare(target) == .orderedSame }
                }
            }
            .map(\.name)
            .filter { candidate in candidate != name && !found.contains { $0.name == candidate } }
            found += next.map { ($0, distance) }
            frontier = next
        }
        return found
    }

    /// Case-insensitive lookup, so `make snap NAME=button` works.
    public static func entry(named name: String) -> CatalogEntry? {
        entries.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
