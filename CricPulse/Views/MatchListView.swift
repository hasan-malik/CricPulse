import SwiftUI

struct MatchListView: View {
    @State private var vm = MatchListViewModel()

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
                        matchList
                    }
                }
            }
            .navigationTitle("CricPulse")
            .navigationBarTitleDisplayMode(.large)
            .tint(CricColors.accent)
            .searchable(text: $vm.searchText, prompt: "Search teams or matches")
            .toolbar { filterMenu }
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Match List

    private var matchList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if vm.liveCount > 0 {
                    HStack(spacing: 6) {
                        LivePulse()
                        Text("\(vm.liveCount) Live \(vm.liveCount == 1 ? "Match" : "Matches")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CricColors.live)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                ForEach(vm.filteredMatches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        MatchRowView(match: match)
                    }
                    .buttonStyle(.plain)
                }

                if vm.filteredMatches.isEmpty && !vm.isLoading {
                    ContentUnavailableView.search(text: vm.searchText)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .trailingAction) {
            Menu {
                ForEach(MatchListViewModel.MatchFilter.allCases, id: \.self) { filter in
                    Button {
                        vm.selectedFilter = filter
                    } label: {
                        Label(filter.rawValue,
                              systemImage: vm.selectedFilter == filter ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }
}

// MARK: - Match Row

struct MatchRowView: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(match.typeColor)
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    MatchTypeBadge(type: match.matchType)
                    if match.isLive { LiveBadge() }
                    Spacer()
                    if let date = match.date {
                        Text(date.prefix(10))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(match.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let scores = match.score, !scores.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(scores.prefix(2), id: \.inning) { score in
                            HStack {
                                Text(score.inning ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(score.display)
                                    .font(.caption.monospacedDigit().weight(.semibold))
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

// MARK: - Supporting Views

struct MatchTypeBadge: View {
    let type: String
    var color: Color {
        switch type.lowercased() {
        case "test":        return CricColors.test
        case "odi":         return CricColors.odi
        case "t20", "t20i": return CricColors.t20
        default:            return .gray
        }
    }
    var body: some View {
        Text(type.uppercased())
            .font(.caption2.weight(.black))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct LiveBadge: View {
    @State private var pulsing = false
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(CricColors.live)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulsing)
                .onAppear { pulsing = true }
            Text("LIVE")
                .font(.caption2.weight(.black))
                .foregroundStyle(CricColors.live)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(CricColors.live.opacity(0.10))
        .clipShape(Capsule())
    }
}

struct ErrorView: View {
    let message: String
    let retry: () async -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Couldn't load matches")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
                .tint(CricColors.accent)
        }
        .padding()
    }
}
