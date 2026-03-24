import SwiftUI

// MARK: - Floating Cricket Ball Particles

struct FloatingBalls: View {

    private struct BallConfig: Identifiable {
        let id = UUID()
        let xFraction: Double
        let startPhase: Double
        let size: CGFloat
        let opacity: Double
        let period: Double
        let driftAmplitude: CGFloat
    }

    private let balls: [BallConfig] = (0..<14).map { _ in
        BallConfig(
            xFraction: Double.random(in: 0.05...0.95),
            startPhase: Double.random(in: 0...1),
            size: CGFloat.random(in: 7...22),
            opacity: Double.random(in: 0.04...0.10),
            period: Double.random(in: 20...45),
            driftAmplitude: CGFloat.random(in: 15...50)
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            GeometryReader { geo in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(balls) { ball in
                        let progress = ((t / ball.period + ball.startPhase)
                            .truncatingRemainder(dividingBy: 1.0))
                        let yPos = geo.size.height * (1.0 - CGFloat(progress)) + ball.size
                        let xDrift = ball.driftAmplitude * CGFloat(sin(progress * .pi * 2))

                        CricketBallShape()
                            .frame(width: ball.size, height: ball.size)
                            .opacity(ball.opacity)
                            .position(
                                x: CGFloat(ball.xFraction) * geo.size.width + xDrift,
                                y: yPos
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Cricket Ball Shape

struct CricketBallShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let r = size * 0.32

            ZStack {
                Circle()
                    .fill(CricColors.accent)

                // Top seam arc
                Path { path in
                    path.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: r,
                        startAngle: .degrees(200),
                        endAngle: .degrees(340),
                        clockwise: false
                    )
                }
                .stroke(.white.opacity(0.55), lineWidth: max(0.8, size * 0.055))

                // Bottom seam arc
                Path { path in
                    path.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: r,
                        startAngle: .degrees(20),
                        endAngle: .degrees(160),
                        clockwise: false
                    )
                }
                .stroke(.white.opacity(0.55), lineWidth: max(0.8, size * 0.055))
            }
        }
    }
}
