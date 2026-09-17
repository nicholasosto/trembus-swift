import AppKit
import SwiftUI
import TrembusTokens

/// Trackpad haptics.
///
/// **Use for snaps and thresholds, not clicks.** A Force Touch click is already a haptic —
/// buzzing again on every button press feels cheap. Good moments: a slider crossing a
/// detent, a dragged item locking into a slot, a meter hitting its limit.
public enum Haptics {
    public enum Pattern: Sendable {
        /// Something lined up or locked into place.
        case snap
        /// Crossed into a different level or zone.
        case level
        /// Anything else worth feeling.
        case generic

        var native: NSHapticFeedbackManager.FeedbackPattern {
            switch self {
            case .snap: .alignment
            case .level: .levelChange
            case .generic: .generic
            }
        }
    }

    public static func play(_ pattern: Pattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern.native, performanceTime: .now)
    }
}

nonisolated private struct HapticsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

nonisolated extension EnvironmentValues {
    /// Turn haptics off for a subtree: `.environment(\.hapticsEnabled, false)`.
    public var hapticsEnabled: Bool {
        get { self[HapticsEnabledKey.self] }
        set { self[HapticsEnabledKey.self] = newValue }
    }
}

extension View {
    /// Play a haptic whenever `trigger` changes.
    public func haptic<T: Equatable>(_ pattern: Haptics.Pattern, trigger: T) -> some View {
        modifier(HapticModifier(pattern: pattern, trigger: trigger))
    }
}

private struct HapticModifier<T: Equatable>: ViewModifier {
    @Environment(\.hapticsEnabled) private var isEnabled
    let pattern: Haptics.Pattern
    let trigger: T

    func body(content: Content) -> some View {
        content.onChange(of: trigger) {
            if isEnabled { Haptics.play(pattern) }
        }
    }
}
