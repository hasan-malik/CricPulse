import SwiftUI

struct HomeView: View {
    @State private var vm = MatchListViewModel()

    var featuredMatches: [Match] {
        let sorted = vm.matches.sorted {
            if $0.isLive != $1.isLive { return $0.isLive }
            return ($0.date ?? "") > ($1.date ?? "")
        }
        return Array(sorted.prefix(6))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.surface.ignoresSafeArea()
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
            .tint(CricColors.accent)
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Featured", subtitle: vm.liveCount > 0 ? "\(vm.liveCount) Live" : nil, liveIndicator: vm.liveCount > 0)
                .padding(.horizontal)
                .padding(.top, 20)

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
            .frame(height: 210)
            .tint(CricColors.accent)
            .padding(.bottom, 4)
        }
    }

    // MARK: - News Section

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Latest News", subtitle: nil, liveIndicator: false)
                .padding(.horizontal)
                .padding(.top, 28)

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
            // White card with subtle type-color gradient at top
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    LinearGradient(
                        colors: [match.typeColor.opacity(0.10), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Left accent bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(match.typeColor)
                    .frame(width: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                // Badges
                HStack(spacing: 8) {
                    MatchTypeBadge(type: match.matchType)
                    if match.isLive { LiveBadge() }
                    Spacer()
                    if let date = match.date {
                        Text(String(date.prefix(10)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Match name
                Text(match.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Scores
                if let scores = match.score, !scores.isEmpty {
                    HStack(spacing: 20) {
                        ForEach(scores.prefix(2), id: \.inning) { score in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(score.inning?.components(separatedBy: " ").first ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(score.display)
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.primary)
                            }
                        }
                        Spacer()
                    }
                }

                // Status
                Text(match.status)
                    .font(.caption)
                    .foregroundStyle(match.isLive ? CricColors.live : .secondary)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .frame(height: 186)
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
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
                .foregroundStyle(.primary)
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
