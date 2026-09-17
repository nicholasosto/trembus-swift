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
        // scaffold:entries — `make new` inserts new components above this line
    ]

    public static func entries(of kind: CatalogEntry.Kind) -> [CatalogEntry] {
        entries.filter { $0.kind == kind }
    }

    /// Case-insensitive lookup, so `make snap NAME=button` works.
    public static func entry(named name: String) -> CatalogEntry? {
        entries.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
