import Foundation

struct NewsItem: Identifiable {
    let id = UUID()
    let headline: String
    let summary: String
    let tag: String
    let tagColor: String   // hex
    let minutesAgo: Int
}

extension NewsItem {
    static let dummyArticles: [NewsItem] = [
        NewsItem(
            headline: "India vs Australia: Bumrah Takes Five-For in Thrilling Test Opener",
            summary: "Jasprit Bumrah delivered a masterclass in reverse swing, claiming 5/43 as Australia were bowled out for 187 on day one.",
            tag: "Test",
            tagColor: "#bf5af2",
            minutesAgo: 12
        ),
        NewsItem(
            headline: "Pakistan Chase Down 320 in Record ODI Run Chase",
            summary: "Babar Azam's unbeaten 147 led Pakistan to their highest successful ODI chase, overhauling South Africa's imposing total with two balls to spare.",
            tag: "ODI",
            tagColor: "#30d158",
            minutesAgo: 45
        ),
        NewsItem(
            headline: "England Announce T20 World Cup Squad: Three Surprise Inclusions",
            summary: "The ECB named a 15-man squad featuring three uncapped players after a series of standout IPL performances turned selectors' heads.",
            tag: "T20",
            tagColor: "#ff9f0a",
            minutesAgo: 92
        ),
        NewsItem(
            headline: "Rohit Sharma Becomes Third Batter to Score 12,000 ODI Runs",
            summary: "The Indian captain reached the landmark milestone during yesterday's match against Sri Lanka, joining Sachin Tendulkar and Kumar Sangakkara in elite company.",
            tag: "Milestone",
            tagColor: "#2997ff",
            minutesAgo: 180
        ),
        NewsItem(
            headline: "IPL 2026: MI vs CSK Preview — The Rivalry Renewed",
            summary: "The most anticipated fixture of the IPL season returns on Saturday. We break down the key battles, pitch conditions, and predicted playing XIs.",
            tag: "IPL",
            tagColor: "#ff6b35",
            minutesAgo: 240
        ),
    ]
}
