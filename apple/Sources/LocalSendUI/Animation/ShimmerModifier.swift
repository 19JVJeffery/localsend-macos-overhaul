import SwiftUI

/// An elegant shimmering effect modifier inspired by markiv/SwiftUI-Shimmer.
/// Applies a specular traveling light sheen across any SwiftUI view.
public struct ShimmerModifier: ViewModifier {
    private let active: Bool
    private let duration: Double
    private let bounce: Bool
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(active: Bool = true, duration: Double = 1.8, bounce: Bool = false) {
        self.active = active
        self.duration = duration
        self.bounce = bounce
    }

    public var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    public func body(content: Content) -> some View {
        if !active || reduceMotion {
            content
        } else {
            content
                .overlay(
                    GeometryReader { geo in
                        let width = geo.size.width
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.35), location: 0.5),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.6)
                        .offset(x: -width * 0.3 + phase * (width * 1.6))
                        .blendMode(.screen)
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(
                        .linear(duration: duration)
                        .repeatForever(autoreverses: bounce)
                    ) {
                        phase = 1.0
                    }
                }
        }
    }
}

public extension View {
    /// Adds a shimmering light sweep highlight across this view.
    func shimmering(active: Bool = true, duration: Double = 1.8, bounce: Bool = false) -> some View {
        modifier(ShimmerModifier(active: active, duration: duration, bounce: bounce))
    }
}
