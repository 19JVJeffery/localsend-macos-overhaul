import SwiftUI
import LocalSendCore

/// Elegant radar scanning animation for device discovery.
public struct RadarScanningView: View {
    public let isScanning: Bool
    public let accentColor: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var wave1: CGFloat = 0.2
    @State private var wave2: CGFloat = 0.2
    @State private var wave3: CGFloat = 0.2
    @State private var rotation: Double = 0

    public init(isScanning: Bool = true, accentColor: Color = LocalSendTheme.accent()) {
        self.isScanning = isScanning
        self.accentColor = accentColor
    }

    public var body: some View {
        ZStack {
            if isScanning && !reduceMotion {
                // Expanding concentric radar rings
                Circle()
                    .stroke(accentColor.opacity(max(0, 0.45 - Double(wave1) * 0.45)), lineWidth: 1.5)
                    .scaleEffect(wave1)

                Circle()
                    .stroke(accentColor.opacity(max(0, 0.45 - Double(wave2) * 0.45)), lineWidth: 1.5)
                    .scaleEffect(wave2)

                Circle()
                    .stroke(accentColor.opacity(max(0, 0.45 - Double(wave3) * 0.45)), lineWidth: 1.5)
                    .scaleEffect(wave3)

                // Soft rotating sweep
                AngularGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(0.18),
                        accentColor.opacity(0.04),
                        Color.clear
                    ]),
                    center: .center
                )
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
                .padding(24)
            } else {
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
                    .scaleEffect(0.9)
            }

            // Central beacon icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 68, height: 68)

                Circle()
                    .fill(accentColor)
                    .frame(width: 48, height: 48)
                    .localSendShadow(LocalSendTheme.shadowAccentGlow)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 240, height: 240)
        .onAppear {
            startAnimationIfNeeded()
        }
        .onChange(of: isScanning) { scanning in
            if scanning { startAnimationIfNeeded() }
        }
    }

    private func startAnimationIfNeeded() {
        guard isScanning && !reduceMotion else { return }

        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        withAnimation(.easeOut(duration: 3.2).repeatForever(autoreverses: false)) {
            wave1 = 1.0
        }
        withAnimation(.easeOut(duration: 3.2).repeatForever(autoreverses: false).delay(1.05)) {
            wave2 = 1.0
        }
        withAnimation(.easeOut(duration: 3.2).repeatForever(autoreverses: false).delay(2.1)) {
            wave3 = 1.0
        }
    }
}
