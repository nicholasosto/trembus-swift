import SwiftUI

/// Motion tokens. Two families:
///
/// - **Curves** — shared with the web, verbatim (`--tcl-ease-calm`, `--tcl-dur-*`).
///   Use for color, opacity, and layout changes.
/// - **Springs** — native only. Use for anything the pointer touches (press, drag, toggle),
///   because a spring carries velocity and a curve cannot.
///
/// Both are stored as DATA (`UnitCurve`, `Spring`) so the gallery can plot the exact
/// curve a component will move along.
public enum Motion {
    public enum Duration: String, CaseIterable, Sendable {
        case fast, base, slow

        public var seconds: Double {
            switch self {
            case .fast: 0.12
            case .base: 0.20
            case .slow: 0.32
            }
        }
    }

    /// `cubic-bezier(0.22, 0.61, 0.36, 1)` — eases out, settles gently.
    public static let easeCalm = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.22, y: 0.61), endControlPoint: UnitPoint(x: 0.36, y: 1))

    /// `cubic-bezier(0.4, 0, 1, 1)` — accelerates away. For things leaving.
    public static let easeExit = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.4, y: 0), endControlPoint: UnitPoint(x: 1, y: 1))

    public static func calm(_ duration: Duration = .base) -> Animation {
        .timingCurve(easeCalm, duration: duration.seconds)
    }

    public static func exit(_ duration: Duration = .fast) -> Animation {
        .timingCurve(easeExit, duration: duration.seconds)
    }

    /// Named springs. Each one has a job — pick by job, not by feel.
    public enum Springs: String, CaseIterable, Sendable {
        /// Going down under the pointer. Fast, no bounce — feels immediate.
        case press
        /// Coming back up. A little overshoot — feels alive.
        case release
        /// A thumb or handle snapping to its new home.
        case snap
        /// Larger pieces arriving (panels, popovers). Soft landing.
        case settle

        public var spring: Spring {
            switch self {
            case .press: Spring(duration: 0.16, bounce: 0)
            case .release: Spring(duration: 0.36, bounce: 0.38)
            case .snap: Spring(duration: 0.30, bounce: 0.24)
            case .settle: Spring(duration: 0.48, bounce: 0.14)
            }
        }
    }

    public static func spring(_ spring: Springs) -> Animation { .spring(spring.spring) }

    /// What to use instead when the user has **Reduce Motion** on: a short plain fade.
    /// State still changes perceivably — it just doesn't travel.
    public static let reduced: Animation = .linear(duration: Duration.fast.seconds)
}
