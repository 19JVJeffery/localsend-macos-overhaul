import SwiftUI
import LocalSendCore

/// Premium radar scanning and discovery animation inspired by high-precision sonar and AirDrop radar.
/// Scales adaptively to fit its container while providing fluid beam rotation, harmonic ripple waves,
/// and responsive signal node pings.
public struct RadarScanningView: View {
    public let isScanning: Bool
    public let accentColor: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sweepAngle: Double = 0
    @State private var wavePhase1: CGFloat = 0.0
    @State private var wavePhase2: CGFloat = 0.0
    @State private var wavePhase3: CGFloat = 0.0
    @State private var beaconBreathing: CGFloat = 1.0

    // Ambient signal nodes around the radar field
    private struct RadarNode: Identifiable {
        let id: Int
        let angleDegrees: Double
        let radiusFraction: CGFloat
        let size: CGFloat
    }

    private let nodes: [RadarNode] = [
        RadarNode(id: 1, angleDegrees: 48, radiusFraction: 0.38, size: 7),
        RadarNode(id: 2, angleDegrees: 135, radiusFraction: 0.65, size: 9),
        RadarNode(id: 3, angleDegrees: 220, radiusFraction: 0.48, size: 8),
        RadarNode(id: 4, angleDegrees: 310, radiusFraction: 0.78, size: 6)
    ]

    public init(isScanning: Bool = true, accentColor: Color = LocalSendTheme.accent()) {
        self.isScanning = isScanning
        self.accentColor = accentColor
    }

    public var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = diameter / 2

            ZStack {
                // 1. Subtle Background Grid & Range Rings
                radarGrid(diameter: diameter, radius: radius)

                if isScanning && !reduceMotion {
                    // 2. Harmonic Expanding Waves
                    expandingWave(phase: wavePhase1, radius: radius)
                    expandingWave(phase: wavePhase2, radius: radius)
                    expandingWave(phase: wavePhase3, radius: radius)

                    // 3. Ambient Signal Nodes (glow brighter when beam passes over)
                    ForEach(nodes) { node in
                        signalNodeView(node: node, radius: radius, center: center)
                    }

                    // 4. Rotating Conic Sweep Beam
                    radarSweepBeam(diameter: diameter)
                }

                // 5. Central Beacon Core
                centralBeacon(diameter: diameter)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .onAppear {
            startAnimationIfNeeded()
        }
        .onChange(of: isScanning) { scanning in
            if scanning { startAnimationIfNeeded() }
        }
    }

    // MARK: - Subviews

    private func radarGrid(diameter: CGFloat, radius: CGFloat) -> some View {
        ZStack {
            // Concentric Range Rings
            ForEach([0.32, 0.62, 0.92], id: \.self) { ringFraction in
                Circle()
                    .stroke(
                        accentColor.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .frame(width: diameter * ringFraction, height: diameter * ringFraction)
            }

            // Outer boundary circle
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
                .frame(width: diameter * 0.95, height: diameter * 0.95)

            // Crosshair Quadrant Reticle (Dashed axes)
            Path { path in
                let span = radius * 0.92
                // Horizontal
                path.move(to: CGPoint(x: -span, y: 0))
                path.addLine(to: CGPoint(x: span, y: 0))
                // Vertical
                path.move(to: CGPoint(x: 0, y: -span))
                path.addLine(to: CGPoint(x: 0, y: span))
            }
            .stroke(
                accentColor.opacity(0.1),
                style: StrokeStyle(lineWidth: 1, dash: [3, 6])
            )
        }
    }

    private func expandingWave(phase: CGFloat, radius: CGFloat) -> some View {
        let size = radius * 2 * (0.2 + phase * 0.78)
        let opacity = max(0.0, Double(1.0 - phase) * 0.42)

        return Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(opacity),
                        accentColor.opacity(opacity * 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .frame(width: size, height: size)
    }

    private func signalNodeView(node: RadarNode, radius: CGFloat, center: CGPoint) -> some View {
        let rad = node.angleDegrees * .pi / 180.0
        let dist = radius * node.radiusFraction
        let x = cos(rad) * dist
        let y = sin(rad) * dist

        // Calculate angular difference between beam and node for proximity glow
        let diff = abs((sweepAngle - node.angleDegrees).truncatingRemainder(dividingBy: 360.0))
        let normalizedDiff = min(diff, 360.0 - diff)
        let proximity = max(0.0, 1.0 - (normalizedDiff / 45.0))

        return ZStack {
            // Glow halo when swept
            if proximity > 0.05 {
                Circle()
                    .fill(accentColor.opacity(Double(proximity) * 0.4))
                    .frame(width: node.size * 2.8, height: node.size * 2.8)
                    .blur(radius: 3)
            }

            // Core node dot
            Circle()
                .fill(
                    proximity > 0.1
                        ? Color.white
                        : accentColor.opacity(0.45)
                )
                .frame(width: node.size, height: node.size)
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.7), lineWidth: 1)
                )
        }
        .offset(x: x, y: y)
        .animation(.easeInOut(duration: 0.15), value: sweepAngle)
    }

    private func radarSweepBeam(diameter: CGFloat) -> some View {
        ZStack {
            // Sweeping Conic Gradient Cone
            Circle()
                .trim(from: 0.0, to: 0.25)
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            accentColor.opacity(0.06),
                            accentColor.opacity(0.24)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(90)
                    )
                )
                .frame(width: diameter * 0.95, height: diameter * 0.95)

            // Crisp leading ray of the sweep
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.0),
                            accentColor.opacity(0.55),
                            accentColor
                        ],
                        startPoint: .center,
                        endPoint: .trailing
                    )
                )
                .frame(width: diameter * 0.47, height: 1.5)
                .offset(x: diameter * 0.235)
                .rotationEffect(.degrees(90))
        }
        .rotationEffect(.degrees(sweepAngle))
    }

    private func centralBeacon(diameter: CGFloat) -> some View {
        let coreSize = max(34.0, diameter * 0.26)
        let iconSize = max(14.0, coreSize * 0.46)

        return ZStack {
            // Outer breathing glow halo
            Circle()
                .fill(accentColor.opacity(0.18))
                .frame(width: coreSize * 1.5, height: coreSize * 1.5)
                .scaleEffect(isScanning && !reduceMotion ? beaconBreathing : 1.0)
                .blur(radius: 4)

            // Middle frosted container
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.35),
                            accentColor.opacity(0.12)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: coreSize * 0.7
                    )
                )
                .frame(width: coreSize * 1.25, height: coreSize * 1.25)

            // Core solid button with soft specular border
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: coreSize, height: coreSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .localSendShadow(LocalSendTheme.shadowAccentGlow)

            // Center Symbol
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Animation Drivers

    private func startAnimationIfNeeded() {
        guard isScanning && !reduceMotion else { return }

        // Continuous smooth rotation (6.5s per revolution)
        withAnimation(.linear(duration: 6.5).repeatForever(autoreverses: false)) {
            sweepAngle = 360
        }

        // Concentric waves phase progression
        withAnimation(.easeOut(duration: 3.0).repeatForever(autoreverses: false)) {
            wavePhase1 = 1.0
        }
        withAnimation(.easeOut(duration: 3.0).repeatForever(autoreverses: false).delay(1.0)) {
            wavePhase2 = 1.0
        }
        withAnimation(.easeOut(duration: 3.0).repeatForever(autoreverses: false).delay(2.0)) {
            wavePhase3 = 1.0
        }

        // Beacon subtle breathing cycle
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            beaconBreathing = 1.15
        }
    }
}
