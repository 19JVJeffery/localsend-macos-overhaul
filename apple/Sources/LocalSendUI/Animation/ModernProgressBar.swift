import SwiftUI

/// Premium multi-layer animated progress bar with smooth interpolation and shimmering highlight.
public struct ModernProgressBar: View {
    public let progress: Double
    public let accentColor: Color
    public let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shimmerOffset: CGFloat = -1.0

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
                // Background Track
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: height)

                // Filled Bar with Gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, filledWidth), height: height)
                    .animation(LocalSendMotion.standard, value: progress)

                // Shimmering Light Sweep (when actively transferring)
                if progress > 0 && progress < 1.0 && !reduceMotion {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.35),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 48, height: height)
                        .offset(x: shimmerOffset * totalWidth)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(height: height)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
            }
        }
    }
}
