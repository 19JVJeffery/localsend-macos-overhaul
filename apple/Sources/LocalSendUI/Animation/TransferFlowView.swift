import SwiftUI

/// Animated fluid data stream communicating active file transfer with traveling kinetic energy pulses.
public struct TransferFlowView: View {
    public let isTransferring: Bool
    public let accentColor: Color
    public let particleCount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: CGFloat = 0.0

    public init(
        isTransferring: Bool = true,
        accentColor: Color = LocalSendTheme.accent(),
        particleCount: Int = 6
    ) {
        self.isTransferring = isTransferring
        self.accentColor = accentColor
        self.particleCount = max(3, particleCount)
    }

    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<particleCount, id: \.self) { index in
                let progress = normalizedProgress(for: index)

                ZStack {
                    // Soft glow halo for active particle
                    if !reduceMotion && isTransferring {
                        Circle()
                            .fill(accentColor.opacity(Double(progress) * 0.45))
                            .frame(width: 8, height: 8)
                            .blur(radius: 2)
                    }

                    // Core bead with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor,
                                    accentColor.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: max(3.0, 4.0 + CGFloat(progress) * 2.5),
                            height: max(3.0, 4.0 + CGFloat(progress) * 2.5)
                        )
                        .opacity(reduceMotion ? 0.7 : (0.2 + Double(progress) * 0.8))
                }
            }
        }
        .onAppear {
            startFlowIfNeeded()
        }
        .onChange(of: isTransferring) { transferring in
            if transferring { startFlowIfNeeded() }
        }
    }

    private func normalizedProgress(for index: Int) -> CGFloat {
        if reduceMotion { return 0.6 }
        let step = 1.0 / CGFloat(particleCount)
        let raw = (CGFloat(index) * step + phase).truncatingRemainder(dividingBy: 1.0)
        // Sine wave bell-curve for smooth fading at ends
        return CGFloat(sin(raw * .pi))
    }

    private func startFlowIfNeeded() {
        guard isTransferring && !reduceMotion else { return }
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }
}
