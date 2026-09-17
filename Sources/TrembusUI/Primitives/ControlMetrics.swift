import SwiftUI
import TrembusTokens

/// Every component's size table, in ONE place.
///
/// Components never take a `size:` parameter. They read SwiftUI's own `controlSize`
/// environment, so `.controlSize(.small)` on a toolbar shrinks every Trembus control in it
/// at once — exactly like native controls.
///
/// ┌─ DENSITY ──────────────────────────────────────────────────────────────────────┐
/// │ Tokens are identical to the web. Control HEIGHTS are not: these are tuned for   │
/// │ a Mac (pointer-precise, denser). The web's touch-friendlier 28 / 36 / 44 button │
/// │ heights are one edit away — change `button` below.                              │
/// └────────────────────────────────────────────────────────────────────────────────┘
nonisolated enum ControlMetrics {
    enum Step: Sendable {
        case sm, md, lg

        init(_ controlSize: ControlSize) {
            switch controlSize {
            case .mini, .small: self = .sm
            case .regular: self = .md
            case .large, .extraLarge: self = .lg
            @unknown default: self = .md
            }
        }
    }

    struct Button {
        let height: CGFloat
        let paddingX: CGFloat
        let type: TypeScale
    }

    static func button(_ step: Step) -> Button {
        switch step {
        case .sm: Button(height: 24, paddingX: Space.s4, type: .sm)
        case .md: Button(height: 30, paddingX: Space.s5, type: .base)
        case .lg: Button(height: 38, paddingX: Space.s6, type: .md)
        }
    }

    struct Badge {
        let height: CGFloat
        let paddingX: CGFloat
        let type: TypeScale
    }

    static func badge(_ step: Step) -> Badge {
        switch step {
        case .sm: Badge(height: 18, paddingX: Space.s3, type: .xs)
        case .md, .lg: Badge(height: 22, paddingX: Space.s4, type: .sm)
        }
    }

    struct Switch {
        let width: CGFloat
        let height: CGFloat
        let inset: CGFloat
        let type: TypeScale

        var thumb: CGFloat { height - inset * 2 }
    }

    static func `switch`(_ step: Step) -> Switch {
        switch step {
        case .sm: Switch(width: 28, height: 16, inset: 2, type: .sm)
        case .md: Switch(width: 36, height: 20, inset: 2, type: .base)
        case .lg: Switch(width: 44, height: 24, inset: 2, type: .md)
        }
    }

    struct Meter {
        let trackHeight: CGFloat
        let type: TypeScale
    }

    static func meter(_ step: Step) -> Meter {
        switch step {
        case .sm: Meter(trackHeight: 4, type: .xs)
        case .md: Meter(trackHeight: 8, type: .sm)
        case .lg: Meter(trackHeight: 12, type: .base)
        }
    }
}
