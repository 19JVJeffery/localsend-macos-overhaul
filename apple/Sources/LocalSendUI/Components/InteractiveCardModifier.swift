import SwiftUI
import LocalSendCore

/// Interactive spring scale and tactile depression modifier inspired by Pow and Explore SwiftUI.
public struct PressableModifier: ViewModifier {
    @State private var isPressed: Bool = false
    public let scale: CGFloat
    public let hapticFeedback: Bool

    public init(scale: CGFloat = 0.97, hapticFeedback: Bool = true) {
        self.scale = scale
        self.hapticFeedback = hapticFeedback
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(LocalSendMotion.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

/// Dynamic glowing border modifier inspired by Shiny.
public struct GlowingBorderModifier: ViewModifier {
    public let color: Color
    public let cornerRadius: CGFloat
    public let isGlowing: Bool

    public init(color: Color, cornerRadius: CGFloat = LocalSendTheme.cornerRadiusCard, isGlowing: Bool = true) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.isGlowing = isGlowing
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isGlowing ? color.opacity(0.8) : color.opacity(0.2),
                                isGlowing ? color.opacity(0.3) : color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isGlowing ? 1.5 : 1
                    )
            )
            .shadow(
                color: isGlowing ? color.opacity(0.25) : Color.clear,
                radius: isGlowing ? 8 : 0,
                x: 0,
                y: isGlowing ? 2 : 0
            )
            .animation(LocalSendMotion.standard, value: isGlowing)
    }
}

public extension View {
    /// Adds responsive spring compression when pressed.
    func pressable(scale: CGFloat = 0.97) -> some View {
        modifier(PressableModifier(scale: scale))
    }

    /// Adds a glowing specular border.
    func glowingBorder(color: Color, cornerRadius: CGFloat = LocalSendTheme.cornerRadiusCard, isGlowing: Bool = true) -> some View {
        modifier(GlowingBorderModifier(color: color, cornerRadius: cornerRadius, isGlowing: isGlowing))
    }
}
