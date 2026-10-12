import SwiftUI

/// Elegant circular progress ring with gradient stroke and glowing indicator tip.
public struct ProgressRingView: View {
    public let progress: Double
    public let accentColor: Color
    public let lineWidth: CGFloat
    public let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        progress: Double,
        accentColor: Color = LocalSendTheme.accent(),
        lineWidth: CGFloat = 6,
        size: CGFloat = 48
    ) {
        self.progress = min(1.0, max(0.0, progress))
        self.accentColor = accentColor
        self.lineWidth = lineWidth
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: lineWidth)

            // Progress Arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.6), accentColor]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(LocalSendMotion.standard, value: progress)

            // Centered Percentage or Icon
            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(LocalSendTheme.success)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.26, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
