import SwiftUI

struct HomeView: View {
    @State private var vm = MatchListViewModel()
    @State private var carouselPosition: String?
    @AppStorage("isDarkMode") private var isDarkMode = false

    var featuredMatches: [Match] {
        let sorted = vm.matches.sorted {
            if $0.isLive != $1.isLive { return $0.isLive }
            return ($0.date ?? "") > ($1.date ?? "")
        }
        return Array(sorted.prefix(6))
    }

    var currentCarouselPage: Int {
        featuredMatches.firstIndex(where: { $0.id == carouselPosition }) ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.surface.ignoresSafeArea()
                FloatingBalls()
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
            .toolbarBackground(CricColors.accent, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .trailingAction) {
                    Button {
                        withAnimation { isDarkMode.toggle() }
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Featured",
                subtitle: vm.liveCount > 0 ? "\(vm.liveCount) Live" : nil,
                liveIndicator: vm.liveCount > 0
            )
            .padding(.horizontal)
            .padding(.top, 20)

            // Peek carousel — next card visible on right edge
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredMatches) { match in
                            NavigationLink(destination: MatchDetailView(match: match)) {
                                FeaturedMatchCard(match: match)
                                    .frame(width: geo.size.width - 48)
                            }
                            .buttonStyle(.plain)
                            .id(match.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $carouselPosition)
            }
            .frame(height: 196)

            // Page dots
            if featuredMatches.count > 1 {
                HStack(spacing: 6) {
                    ForEach(featuredMatches.indices, id: \.self) { i in
                        Capsule()
                            .fill(currentCarouselPage == i
                                  ? CricColors.accent
                                  : Color.gray.opacity(0.25))
                            .frame(width: currentCarouselPage == i ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: currentCarouselPage)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            }
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
            RoundedRectangle(cornerRadius: 20)
                .fill(CricColors.card)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
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

                // Team names with flags
                HStack(spacing: 6) {
                    if let t1 = match.teams.first {
                        Text(t1.teamFlag)
                        Text(t1.teamAbbreviation)
                            .font(.title3.weight(.black))
                    }
                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                    if match.teams.count > 1 {
                        Text(match.teams[1].teamFlag)
                        Text(match.teams[1].teamAbbreviation)
                            .font(.title3.weight(.black))
                    }
                }

                // Scores — bigger
                if let scores = match.score, !scores.isEmpty {
                    HStack(spacing: 20) {
                        ForEach(scores.prefix(2), id: \.inning) { score in
                            VStack(alignment: .leading, spacing: 1) {
                                Text((score.inning?.components(separatedBy: " ").first ?? "").teamAbbreviation)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(score.display)
                                    .font(.title2.weight(.black).monospacedDigit())
                            }
                        }
                        Spacer()
                    }
                }

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
