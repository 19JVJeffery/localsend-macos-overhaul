import SwiftUI
import LocalSendCore

/// Subtle floating ambient lighting mesh that adds depth and life to the application backdrop,
/// reminiscent of modern macOS Sonoma/Sequoia and iOS system materials.
public struct AmbientBackgroundView: View {
    public let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateAura: Bool = false

    public init(accentColor: Color = LocalSendTheme.accent()) {
        self.accentColor = accentColor
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = max(geometry.size.width, geometry.size.height)

            ZStack {
                // Base background fill
                LocalSendTheme.windowBackground(colorScheme: colorScheme)
                    .ignoresSafeArea()

                if !reduceMotion {
                    // Top-leading subtle teal aura
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(colorScheme == .dark ? 0.09 : 0.06),
                                    accentColor.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: size * 0.45
                            )
                        )
                        .frame(width: size * 0.9, height: size * 0.9)
                        .offset(
                            x: animateAura ? -size * 0.15 : -size * 0.25,
                            y: animateAura ? -size * 0.1 : -size * 0.2
                        )
                        .blur(radius: 60)

                    // Bottom-trailing soft mint aura
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    LocalSendTheme.Brand.teal300.opacity(colorScheme == .dark ? 0.06 : 0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: size * 0.4
                            )
                        )
                        .frame(width: size * 0.8, height: size * 0.8)
                        .offset(
                            x: animateAura ? size * 0.2 : size * 0.1,
                            y: animateAura ? size * 0.25 : size * 0.15
                        )
                        .blur(radius: 70)
                }
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        .easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateAura = true
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
