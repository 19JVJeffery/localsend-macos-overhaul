import SwiftUI

/// Reusable motion tokens, spring presets, and animation helpers respecting Reduce Motion.
public enum LocalSendMotion {
    // MARK: - Spring Presets
    /// Ultra-responsive spring for button clicks, toggle states, and tactile interactions.
    public static let snappy = Animation.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0)

    /// Standard natural spring for list insertion, item movement, and standard layout shifts.
    public static let standard = Animation.spring(response: 0.36, dampingFraction: 0.82, blendDuration: 0)

    /// Smooth, elegant spring for card expansion, shape morphing, and sheet presentation.
    public static let smooth = Animation.spring(response: 0.46, dampingFraction: 0.88, blendDuration: 0)

    /// Gentle, relaxed spring for ambient breathing, background waves, and settling effects.
    public static let gentle = Animation.spring(response: 0.62, dampingFraction: 0.92, blendDuration: 0)

    /// Playful, energetic spring for success checkmarks, particle bursts, and completion pops.
    public static let bouncy = Animation.spring(response: 0.40, dampingFraction: 0.65, blendDuration: 0)

    // MARK: - Timing Constants
    public static let durationFast: Double = 0.16
    public static let durationStandard: Double = 0.28
    public static let durationMedium: Double = 0.42
    public static let durationLong: Double = 0.75

    // MARK: - Reduce Motion Adaptive Animation
    public static func adaptive(
        _ animation: Animation = standard,
        reduceMotion: Bool,
        fallback: Animation = .easeInOut(duration: durationFast)
    ) -> Animation {
        reduceMotion ? fallback : animation
    }
}

public struct MotionSensitiveModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation

    public func body(content: Content) -> some View {
        content.animation(reduceMotion ? .easeInOut(duration: 0.15) : animation, value: UUID())
    }
}

public extension View {
    func localSendMotionAnimation(_ animation: Animation = LocalSendMotion.standard) -> some View {
        self.modifier(MotionSensitiveModifier(animation: animation))
    }
}
