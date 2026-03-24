import SwiftUI

struct MatchesTabView: View {
    @State private var vm = MatchListViewModel()

    var liveMatches:     [Match] { vm.matches.filter { $0.isLive } }
    var upcomingMatches: [Match] { vm.matches.filter { $0.matchStarted == false || $0.matchStarted == nil } }
    var recentMatches:   [Match] { vm.matches.filter { $0.matchEnded == true } }

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.background.ignoresSafeArea()

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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $vm.searchText, prompt: "Search teams or matches")
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Sections

    private var matchSections: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {

                // Live
                if !liveMatches.isEmpty {
                    MatchSection(
                        title: "Live Now",
                        subtitle: "\(liveMatches.count) match\(liveMatches.count == 1 ? "" : "es")",
                        isLive: true,
                        matches: filteredSection(liveMatches)
                    )
                }

                // Upcoming
                let upcoming = filteredSection(upcomingMatches)
                if !upcoming.isEmpty {
                    MatchSection(
                        title: "Upcoming",
                        subtitle: nil,
                        isLive: false,
                        matches: upcoming
                    )
                }

                // Recent
                let recent = filteredSection(recentMatches)
                if !recent.isEmpty {
                    MatchSection(
                        title: "Recent Results",
                        subtitle: nil,
                        isLive: false,
                        matches: recent
                    )
                }

                if vm.filteredMatches.isEmpty && !vm.isLoading {
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
    let subtitle: String?
    let isLive: Bool
    let matches: [Match]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                if isLive {
                    LivePulse()
                }
                Text(title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isLive ? CricColors.live : .secondary)
                }
                Spacer()
                Text("\(matches.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 4)

            ForEach(matches) { match in
                NavigationLink(destination: MatchDetailView(match: match)) {
                    DarkMatchRow(match: match)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Dark Match Row

struct DarkMatchRow: View {
    let match: Match

    var body: some View {
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

            Text(match.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let scores = match.score, !scores.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(scores.prefix(2), id: \.inning) { score in
                        HStack {
                            Text(score.inning?.components(separatedBy: " ").prefix(3).joined(separator: " ") ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text(score.display)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.white)
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
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(match.isLive ? CricColors.live.opacity(0.4) : CricColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Live Pulse Dot

private struct LivePulse: View {
    @State private var pulsing = false
    var body: some View {
        Circle()
            .fill(CricColors.live)
            .frame(width: 8, height: 8)
            .scaleEffect(pulsing ? 1.5 : 1.0)
            .opacity(pulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulsing)
            .onAppear { pulsing = true }
    }
}
