import SwiftUI

/// Premium multi-layer animated progress bar with smooth interpolation,
/// traveling specular shimmer, and an illuminated leading edge beacon.
public struct ModernProgressBar: View {
    public let progress: Double
    public let accentColor: Color
    public let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shimmerOffset: CGFloat = -1.0
    @State private var pulseHead: Bool = false

    public init(
        progress: Double,
        accentColor: Color = LocalSendTheme.accent(),
        height: CGFloat = 8
    ) {
        self.progress = min(1.0, max(0.0, progress))
        self.accentColor = accentColor
        self.height = height
    }

    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let filledWidth = totalWidth * CGFloat(progress)

            ZStack(alignment: .leading) {
                // 1. Background Track with inner shadow feel
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: height)
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.06), lineWidth: 1)
                    )

                // 2. Filled Gradient Bar
                if progress > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.8),
                                    accentColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(height, filledWidth), height: height)
                        .overlay(
                            // Specular top highlight reflection
                            VStack {
                                Capsule()
                                    .fill(Color.white.opacity(0.35))
                                    .frame(height: max(1.5, height * 0.28))
                                    .padding(.horizontal, 2)
                                    .padding(.top, 1)
                                Spacer()
                            }
                            .clipShape(Capsule())
                        )
                        .animation(LocalSendMotion.standard, value: progress)

                    // 3. Illuminated Leading Edge Tip
                    if progress < 1.0 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: max(4.0, height * 0.65), height: max(4.0, height * 0.65))
                            .localSendShadow(LocalSendTheme.shadowAccentGlow)
                            .offset(x: max(0, filledWidth - height * 0.8))
                            .scaleEffect(pulseHead && !reduceMotion ? 1.2 : 1.0)
                    }

                    // 4. Shimmering Light Sweep (when active transfer)
                    if progress > 0 && progress < 1.0 && !reduceMotion {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 50, height: height)
                            .offset(x: shimmerOffset * totalWidth)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(height: height)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseHead = true
                }
            }
        }
    }
}
