import SwiftUI

/// How far a surface floats above the page. `.e2` ↔ `--tcl-elevation-2`.
public enum Elevation: Int, CaseIterable, Sendable {
    case e0, e1, e2, e3
}

/// One CSS `box-shadow` layer: `0 4px 12px rgba(…)` → `y: 4, blur: 12`.
public struct ShadowLayer: Sendable, Hashable {
    public var color: ColorValue
    public var blur: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(_ color: ColorValue, blur: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.blur = blur
        self.x = x
        self.y = y
    }

    /// SwiftUI's shadow `radius` is roughly half a CSS blur radius.
    public var radius: CGFloat { blur / 2 }
}

/// A resolved elevation: stacked shadows, plus the faint 1pt hairline dark themes use
/// instead of heavy drop-shadows.
public struct ElevationStyle: Sendable, Hashable {
    public var shadows: [ShadowLayer]
    public var hairline: ColorValue?

    public init(shadows: [ShadowLayer] = [], hairline: ColorValue? = nil) {
        self.shadows = shadows
        self.hairline = hairline
    }

    public static let none = ElevationStyle()
}

/// The four elevation levels of one theme.
public struct ElevationScale: Sendable, Hashable {
    public var e1: ElevationStyle
    public var e2: ElevationStyle
    public var e3: ElevationStyle

    public subscript(level: Elevation) -> ElevationStyle {
        switch level {
        case .e0: .none
        case .e1: e1
        case .e2: e2
        case .e3: e3
        }
    }
}
