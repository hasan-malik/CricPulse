import SwiftUI

struct HomeView: View {
    @State private var vm = MatchListViewModel()

    var featuredMatches: [Match] {
        let sorted = vm.matches.sorted {
            // Live first, then by date descending
            if $0.isLive != $1.isLive { return $0.isLive }
            return ($0.date ?? "") > ($1.date ?? "")
        }
        return Array(sorted.prefix(6))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if !vm.matches.isEmpty {
                            featuredCarousel
                        }
                        newsSection
                    }
                }
            }
            .navigationTitle("CricPulse")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Featured", subtitle: vm.liveCount > 0 ? "\(vm.liveCount) Live" : nil, liveIndicator: vm.liveCount > 0)
                .padding(.horizontal)
                .padding(.top, 16)

            TabView {
                ForEach(featuredMatches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        FeaturedMatchCard(match: match)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 200)
            .padding(.bottom, 8)
        }
    }

    // MARK: - News Section

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Latest News", subtitle: nil, liveIndicator: false)
                .padding(.horizontal)
                .padding(.top, 24)

            ForEach(NewsItem.dummyArticles) { article in
                NewsCard(article: article)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Featured Match Card

struct FeaturedMatchCard: View {
    let match: Match

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [match.typeColor.opacity(0.8), CricColors.card],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(match.typeColor.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                // Badges
                HStack(spacing: 8) {
                    MatchTypeBadge(type: match.matchType)
                    if match.isLive { LiveBadge() }
                    Spacer()
                    if let date = match.date {
                        Text(String(date.prefix(10)))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Match name
                Text(match.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Scores
                if let scores = match.score, !scores.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(scores.prefix(2), id: \.inning) { score in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(score.inning?.components(separatedBy: " ").first ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(score.display)
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.white)
                            }
                        }
                        Spacer()
                    }
                }

                // Status
                Text(match.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(16)
        }
        .frame(height: 176)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let liveIndicator: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
            if liveIndicator, let sub = subtitle {
                HStack(spacing: 4) {
                    Circle().fill(CricColors.live).frame(width: 6, height: 6)
                    Text(sub)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CricColors.live)
                }
            }
            Spacer()
        }
    }
}
