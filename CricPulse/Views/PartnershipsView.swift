import SwiftUI

struct PartnershipsView: View {
    let partnerships: [CSPartnership]

    private var totalRuns: Int { partnerships.reduce(0) { $0 + $1.runs } }

    private let barColors: [Color] = [
        CricColors.accent, CricColors.t20, CricColors.odi, CricColors.test,
        Color.cyan, Color.purple, Color.pink, Color.yellow,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Partnerships")
                .font(.headline.weight(.bold))

            if partnerships.isEmpty {
                Text("No partnership data")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(partnerships.enumerated()), id: \.offset) { idx, p in
                    partnershipRow(p, index: idx)
                    if idx < partnerships.count - 1 { Divider() }
                }
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }

    private func partnershipRow(_ p: CSPartnership, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(p.batter1.components(separatedBy: " ").last ?? p.batter1) & \(p.batter2.components(separatedBy: " ").last ?? p.batter2)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(p.runs)")
                        .font(.subheadline.weight(.black).monospacedDigit())
                    Text("\(p.balls)b")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            // Proportional bar
            GeometryReader { geo in
                let fraction: CGFloat = totalRuns > 0
                    ? min(1, CGFloat(p.runs) / CGFloat(totalRuns))
                    : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColors[index % barColors.count])
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: fraction)
                }
            }
            .frame(height: 6)

            if let kind = p.endedBy {
                Text(kind.capitalized)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
