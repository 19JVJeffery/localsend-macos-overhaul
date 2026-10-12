import SwiftUI

/// Animated data stream communicating active file transfer.
public struct TransferFlowView: View {
    public let isTransferring: Bool
    public let accentColor: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: CGFloat = 0

    public init(isTransferring: Bool = true, accentColor: Color = LocalSendTheme.accent()) {
        self.isTransferring = isTransferring
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(accentColor)
                    .frame(width: 5, height: 5)
                    .opacity(particleOpacity(for: index))
                    .scaleEffect(particleScale(for: index))
            }
        }
        .onAppear {
            if isTransferring && !reduceMotion {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
        }
    }

    private func particleOpacity(for index: Int) -> Double {
        if reduceMotion { return 0.6 }
        let offset = (CGFloat(index) / 5.0 + phase).truncatingRemainder(dividingBy: 1.0)
        return Double(sin(offset * .pi)) * 0.8 + 0.2
    }

    private func particleScale(for index: Int) -> CGFloat {
        if reduceMotion { return 1.0 }
        let offset = (CGFloat(index) / 5.0 + phase).truncatingRemainder(dividingBy: 1.0)
        return 0.8 + CGFloat(sin(offset * .pi)) * 0.4
    }
}
