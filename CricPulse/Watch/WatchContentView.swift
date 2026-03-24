#if os(watchOS)
import SwiftUI

// MARK: - Root Match List

struct WatchContentView: View {
    @State private var vm = MatchListViewModel()

    private var live:   [Match] { vm.matches.filter { $0.isLive } }
    private var recent: [Match] { vm.matches.filter { $0.matchEnded == true } }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.matches.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading…").font(.caption2).foregroundStyle(.secondary)
                    }
                } else if let err = vm.error, vm.matches.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.title2).foregroundStyle(CricColors.accent)
                        Text(err)
                            .font(.caption2).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        if !live.isEmpty {
                            Section {
                                ForEach(live.prefix(5)) { match in
                                    NavigationLink(destination: WatchMatchDetailView(match: match)) {
                                        WatchMatchRow(match: match, isLive: true)
                                    }
                                }
                            } header: {
                                HStack(spacing: 4) {
                                    Circle().fill(CricColors.live).frame(width: 6, height: 6)
                                    Text("LIVE")
                                        .font(.caption2.weight(.black))
                                        .foregroundStyle(CricColors.live)
                                }
                            }
                        }

                        if !recent.isEmpty {
                            Section("Recent") {
                                ForEach(recent.prefix(10)) { match in
                                    NavigationLink(destination: WatchMatchDetailView(match: match)) {
                                        WatchMatchRow(match: match, isLive: false)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("CricPulse")
        }
        .task { await vm.load() }
    }
}

// MARK: - Match Row

struct WatchMatchRow: View {
    let match: Match
    let isLive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(match.shortMatchup)
                .font(.body.weight(.bold))
                .lineLimit(1)

            if let scores = match.score, !scores.isEmpty {
                ForEach(scores.prefix(2), id: \.inning) { score in
                    let name = match.teams.first(where: { (score.inning ?? "").hasPrefix($0) }) ?? ""
                    HStack {
                        Text(name.teamFlag + " " + name.teamAbbreviation)
                            .font(.caption2.weight(.semibold))
                        Spacer()
                        Text(score.display)
                            .font(.caption2.monospacedDigit())
                    }
                }
            } else {
                Text(match.status)
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
#endif
