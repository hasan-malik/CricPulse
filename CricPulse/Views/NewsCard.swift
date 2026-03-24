import SwiftUI

struct NewsCard: View {
    let article: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(article.tag)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(hex: article.tagColor))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: article.tagColor).opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Text(timeAgo(article.minutesAgo))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(article.headline)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(article.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(14)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CricColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func timeAgo(_ minutes: Int) -> String {
        if minutes < 60  { return "\(minutes)m ago" }
        if minutes < 1440 { return "\(minutes / 60)h ago" }
        return "\(minutes / 1440)d ago"
    }
}
