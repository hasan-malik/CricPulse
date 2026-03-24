import SwiftUI

struct MatchListView: View {
    @State private var vm = MatchListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.groupedBackground.ignoresSafeArea()

                Group {
                    if vm.isLoading && vm.matches.isEmpty {
                        ProgressView("Loading matches…")
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
            .searchable(text: $vm.searchText, prompt: "Search teams or matches")
            .toolbar { filterMenu }
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - Match List

    private var matchList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Live badge header
                if vm.liveCount > 0 {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(.red)
                        Text("\(vm.liveCount) Live \(vm.liveCount == 1 ? "Match" : "Matches")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
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
        VStack(alignment: .leading, spacing: 10) {
            // Header: type badge + live indicator + date
            HStack {
                MatchTypeBadge(type: match.matchType)
                if match.isLive {
                    LiveBadge()
                }
                Spacer()
                if let date = match.date {
                    Text(date.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Teams
            Text(match.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Scores
            if let scores = match.score, !scores.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(scores.prefix(2), id: \.inning) { score in
                        HStack {
                            Text(score.inning ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text(score.display)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.top, 2)
            }

            // Status
            Text(match.status)
                .font(.caption)
                .foregroundStyle(match.isLive ? .red : .secondary)
                .lineLimit(2)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Supporting Views

struct MatchTypeBadge: View {
    let type: String
    var color: Color {
        switch type.lowercased() {
        case "test": return .purple
        case "odi":  return .blue
        case "t20":  return .orange
        default:     return .gray
        }
    }
    var body: some View {
        Text(type.uppercased())
            .font(.caption2.weight(.black))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct LiveBadge: View {
    @State private var pulsing = false
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulsing)
                .onAppear { pulsing = true }
            Text("LIVE")
                .font(.caption2.weight(.black))
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.red.opacity(0.1))
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
        }
        .padding()
    }
}
