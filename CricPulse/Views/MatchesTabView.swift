import SwiftUI

struct MatchesTabView: View {
    @State private var vm = MatchListViewModel()

    var liveMatches:     [Match] { vm.matches.filter { $0.isLive } }
    var upcomingMatches: [Match] { vm.matches.filter { $0.matchStarted == false || $0.matchStarted == nil } }
    var recentMatches:   [Match] { vm.matches.filter { $0.matchEnded == true } }

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.surface.ignoresSafeArea()

                Group {
                    if vm.isLoading && vm.matches.isEmpty {
                        ProgressView("Loading matches…")
                            .tint(CricColors.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = vm.error, vm.matches.isEmpty {
                        ErrorView(message: error) { await vm.load() }
                    } else {
                        matchSections
                    }
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
            .tint(CricColors.accent)
            .searchable(text: $vm.searchText, prompt: "Search teams or matches")
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Sections

    private var matchSections: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {

                if !liveMatches.isEmpty {
                    MatchSection(title: "Live Now", count: liveMatches.count, isLive: true,
                                 matches: filteredSection(liveMatches))
                }

                let upcoming = filteredSection(upcomingMatches)
                if !upcoming.isEmpty {
                    MatchSection(title: "Upcoming", count: upcoming.count, isLive: false,
                                 matches: upcoming)
                }

                let recent = filteredSection(recentMatches)
                if !recent.isEmpty {
                    MatchSection(title: "Recent Results", count: recent.count, isLive: false,
                                 matches: recent)
                }

                if vm.matches.isEmpty && !vm.isLoading {
                    ContentUnavailableView.search(text: vm.searchText)
                        .padding(.top, 60)
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func filteredSection(_ matches: [Match]) -> [Match] {
        guard !vm.searchText.isEmpty else { return matches }
        return matches.filter {
            $0.name.localizedCaseInsensitiveContains(vm.searchText) ||
            $0.teams.joined().localizedCaseInsensitiveContains(vm.searchText)
        }
    }
}

// MARK: - Match Section

private struct MatchSection: View {
    let title: String
    let count: Int
    let isLive: Bool
    let matches: [Match]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 6) {
                if isLive {
                    LivePulse()
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CricColors.accent)
                        .frame(width: 3, height: 18)
                }
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 2)

            ForEach(matches) { match in
                NavigationLink(destination: MatchDetailView(match: match)) {
                    MatchCard(match: match)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored type strip
            HStack(spacing: 0) {
                Rectangle()
                    .fill(match.typeColor)
                    .frame(height: 3)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    MatchTypeBadge(type: match.matchType)
                    if match.isLive { LiveBadge() }
                    Spacer()
                    if let date = match.date {
                        Text(String(date.prefix(10)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if let t1 = match.teams.first {
                            Text(t1.teamFlag + " " + t1.teamAbbreviation)
                                .font(.subheadline.weight(.black))
                        }
                        Text("vs").font(.caption).foregroundStyle(.secondary)
                        if match.teams.count > 1 {
                            Text(match.teams[1].teamFlag + " " + match.teams[1].teamAbbreviation)
                                .font(.subheadline.weight(.black))
                        }
                    }
                    if !match.seriesContext.isEmpty {
                        Text(match.seriesContext)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let scores = match.score, !scores.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(scores.prefix(2), id: \.inning) { score in
                            HStack {
                                Text((score.inning?.components(separatedBy: " ").first ?? "").teamAbbreviation)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(score.display)
                                    .font(.subheadline.monospacedDigit().weight(.black))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                Text(match.status)
                    .font(.caption)
                    .foregroundStyle(match.isLive ? CricColors.live : .secondary)
                    .lineLimit(2)
            }
            .padding(14)
        }
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(match.isLive ? CricColors.live.opacity(0.3) : CricColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Live Pulse Dot

struct LivePulse: View {
    @State private var pulsing = false
    var body: some View {
        Circle()
            .fill(CricColors.live)
            .frame(width: 8, height: 8)
            .scaleEffect(pulsing ? 1.5 : 1.0)
            .opacity(pulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulsing)
            .onAppear { pulsing = true }
    }
}
