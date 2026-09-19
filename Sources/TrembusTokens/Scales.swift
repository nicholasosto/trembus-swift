import SwiftUI

// Theme-invariant scales. Same steps, same values as `:root` in tokens.light.css.
// Points on macOS == CSS px on the web.

/// Spacing — 4pt base. `Space.s4` ↔ `--tcl-space-4`.
public enum Space {
    public static let s0: CGFloat = 0
    public static let s1: CGFloat = 2
    public static let s2: CGFloat = 4
    public static let s3: CGFloat = 8
    public static let s4: CGFloat = 12
    public static let s5: CGFloat = 16
    public static let s6: CGFloat = 24
    public static let s7: CGFloat = 32
    public static let s8: CGFloat = 48

    /// Every step in order, for iteration (the gallery's spacing sheet, tests).
    public static let steps: [CGFloat] = [s0, s1, s2, s3, s4, s5, s6, s7, s8]
}

/// Corner radius. `md` (5pt) is the Trembus kit button radius.
public enum Radius: String, CaseIterable, Sendable {
    case none, sm, md, lg, full

    public var value: CGFloat {
        switch self {
        case .none: 0
        case .sm: 4
        case .md: 5
        case .lg: 10
        case .full: 9999
        }
    }
}

/// Type sizes. `TypeScale.base` ↔ `--tcl-text-base`.
public enum TypeScale: String, CaseIterable, Sendable {
    case xs, sm, base, md, lg, xl

    public var size: CGFloat {
        switch self {
        case .xs: 11
        case .sm: 12
        case .base: 14
        case .md: 16
        case .lg: 20
        case .xl: 28
        }
    }

    /// Letter-spacing in points for this size (CSS tracks in `em`).
    public func tracking(_ tracking: Tracking) -> CGFloat { size * tracking.em }
}

/// Letter-spacing, in `em`.
public enum Tracking: Sendable {
    case normal, wide, caps

    public var em: CGFloat {
        switch self {
        case .normal: 0
        case .wide: 0.06
        case .caps: 0.14
        }
    }
}

/// Opacity steps that aren't a color.
public enum Opacity {
    /// A disabled control: dimmed, but still legible. ONE value, so every control agrees —
    /// change it here, not at the call sites.
    public static let disabled: Double = 0.6
}

// MARK: - Typography

public enum FontFamily: String, CaseIterable, Sendable {
    /// SF Pro — the system face.
    case sans
    /// SF Mono — numbers, code, tabular data.
    case mono
    /// Serif display — expressive title work (New York stands in for Cinzel).
    case display
}

extension Font {
    /// `.font(.trembus(.sm, weight: .medium))`
    public static func trembus(
        _ step: TypeScale = .base, weight: Font.Weight = .regular, family: FontFamily = .sans
    ) -> Font {
        switch family {
        case .sans: .system(size: step.size, weight: weight, design: .default)
        case .mono: .system(size: step.size, weight: weight, design: .monospaced)
        case .display: .system(size: step.size, weight: weight, design: .serif)
        }
    }
}
