import SwiftUI

// MARK: - Cricket Facts

private let cricketFacts: [String] = [
    "The fastest delivery ever recorded was 161.3 km/h by Shoaib Akhtar in 2003.",
    "Sachin Tendulkar scored 100 international centuries — no one else has reached 80.",
    "Don Bradman's Test average of 99.94 is considered the greatest in any sport.",
    "The longest Test match lasted 9 days — England vs South Africa, Durban 1939.",
    "MS Dhoni is the only captain to win all three major ICC trophies.",
    "A red cricket ball can swing up to 30cm in humid conditions.",
    "The first Cricket World Cup was held in England in 1975.",
    "Brian Lara scored 400* — the highest individual Test innings ever.",
    "Muttiah Muralitharan took 800 Test wickets, the most in history.",
    "The Ashes urn is only 10.5 cm tall — yet it defines a rivalry between nations.",
]

// MARK: - Splash View

struct SplashView: View {
    @State private var scale: CGFloat = 0.35
    @State private var opacity: Double = 0.0
    @State private var ballRotation: Double = 0.0

    private let fact = cricketFacts.randomElement() ?? cricketFacts[0]

    var body: some View {
        ZStack {
            CricColors.accent.ignoresSafeArea()

            VStack(spacing: 28) {
                // Spinning cricket ball logo
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                    CricketBallShape()
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(ballRotation))
                }

                VStack(spacing: 6) {
                    Text("CricPulse")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(.white)
                    Text("Live Cricket · Every Platform")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Random fact
                Text("📖  \(fact)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }
        }
    }
}
