import SwiftUI

struct FallOfWicketsView: View {
    let fow: [CSFoW]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fall of Wickets")
                .font(.headline.weight(.bold))

            if fow.isEmpty {
                Text("No wicket data")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                // Column header
                HStack {
                    Text("#").frame(width: 18, alignment: .leading)
                    Text("Batsman").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Score").frame(width: 50, alignment: .trailing)
                    Text("Over").frame(width: 42, alignment: .trailing)
                    Text("How").frame(width: 64, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Divider()

                ForEach(fow) { w in
                    HStack {
                        Text("\(w.wicket)")
                            .frame(width: 18, alignment: .leading)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(CricColors.accent)
                        Text(w.playerOut ?? "-")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text("\(w.runs)")
                            .frame(width: 50, alignment: .trailing)
                            .font(.subheadline.monospacedDigit().weight(.black))
                        Text(w.over)
                            .frame(width: 42, alignment: .trailing)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(w.kind?.capitalized ?? "-")
                            .frame(width: 64, alignment: .trailing)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Divider()
                }
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }
}
