import SwiftUI

/// Satisfying completion animation featuring an animated checkmark and short particle burst.
public struct SuccessCelebrationView: View {
    public let message: String
    public let onDismiss: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var checkmarkScale: CGFloat = 0.3
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.8
    @State private var particles: [Particle] = []
    @State private var isVisible = true

    public init(message: String = "Transfer Completed!", onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            if !reduceMotion {
                // Expanding ripple
                Circle()
                    .stroke(LocalSendTheme.success.opacity(rippleOpacity), lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .frame(width: 80, height: 80)

                // Particle Canvas
                ParticleCanvasView(particles: $particles)
                    .frame(width: 180, height: 180)
            }

            // Checkmark Icon
            VStack(spacing: LocalSendTheme.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(LocalSendTheme.success.opacity(0.18))
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(LocalSendTheme.success)
                        .frame(width: 48, height: 48)

                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)

                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(LocalSendTheme.spacingLarge)
        .onAppear {
            triggerCelebration()
        }
    }

    private func triggerCelebration() {
        if reduceMotion {
            checkmarkScale = 1.0
            return
        }

        // 1. Spring in checkmark
        withAnimation(LocalSendMotion.bouncy) {
            checkmarkScale = 1.0
        }

        // 2. Expand and fade ripple
        withAnimation(.easeOut(duration: 0.7)) {
            rippleScale = 1.6
            rippleOpacity = 0.0
        }

        // 3. Emit small particle burst
        spawnParticles()

        // 4. Animate particles over 0.8s
        let timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { t in
            var allDead = true
            for i in particles.indices {
                if particles[i].life > 0 {
                    particles[i].x += particles[i].vx
                    particles[i].y += particles[i].vy
                    particles[i].vy += 0.08 // slight gravity
                    particles[i].vx *= 0.96 // drag
                    particles[i].life -= 0.016
                    allDead = false
                }
            }
            if allDead {
                t.invalidate()
                onDismiss?()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func spawnParticles() {
        var newParticles: [Particle] = []
        let colors: [Color] = [
            LocalSendTheme.success,
            LocalSendTheme.Brand.teal300,
            Color.yellow.opacity(0.85),
            LocalSendTheme.Brand.teal500
        ]

        for _ in 0..<28 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 2.2...5.8)
            let color = colors.randomElement() ?? LocalSendTheme.success

            newParticles.append(Particle(
                x: 90,
                y: 90,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                size: Double.random(in: 3.5...6.5),
                color: color,
                opacity: 0.9,
                maxLife: Double.random(in: 0.55...0.85)
            ))
        }
        self.particles = newParticles
    }
}
