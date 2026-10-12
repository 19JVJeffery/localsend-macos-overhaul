import SwiftUI

/// A single particle definition for the Canvas renderer.
public struct Particle: Identifiable, Sendable {
    public let id = UUID()
    public var x: Double
    public var y: Double
    public var vx: Double
    public var vy: Double
    public var size: Double
    public var color: Color
    public var opacity: Double
    public var life: Double
    public let maxLife: Double

    public init(
        x: Double,
        y: Double,
        vx: Double,
        vy: Double,
        size: Double,
        color: Color,
        opacity: Double = 1.0,
        maxLife: Double
    ) {
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.size = size
        self.color = color
        self.opacity = opacity
        self.life = maxLife
        self.maxLife = maxLife
    }

    public var isAlive: Bool { life > 0 }
}

/// High-performance SwiftUI Canvas particle emitter and renderer.
public struct ParticleCanvasView: View {
    @Binding var particles: [Particle]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(particles: Binding<[Particle]>) {
        self._particles = particles
    }

    public var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            Canvas { context, _ in
                for particle in particles {
                    guard particle.isAlive else { continue }
                    let rect = CGRect(
                        x: particle.x - particle.size / 2,
                        y: particle.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.opacity = particle.opacity * (particle.life / particle.maxLife)
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
            .allowsHitTesting(false)
        }
    }
}
