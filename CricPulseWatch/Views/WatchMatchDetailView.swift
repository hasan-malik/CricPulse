import SwiftUI

// MARK: - Match Detail
//
// Compact scorecard for Apple Watch: innings selector → top batsmen + bowlers.
// Charts and wagon wheel are omitted — screen too small, battery too precious.
// CricSheets enrichment is intentionally skipped: the backend runs on localhost
// and is unreachable from a physical watch (companion phone handles data).

struct WatchMatchDetailView: View {
    let match: Match
    @State private var vm = MatchDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                if match.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(CricColors.live).frame(width: 6, height: 6)
                        Text("LIVE").font(.caption2.weight(.black)).foregroundStyle(CricColors.live)
                    }
                }

                if vm.isLoading && vm.scorecard == nil {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let innings = vm.selectedInnings {
                    inningsPicker
                    scoreHeader(innings: innings)
                    Divider()
                    battingSection(innings: innings)
                    Divider()
                    bowlingSection(innings: innings)
                } else if !vm.isLoading {
                    fallbackScores
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(match.shortMatchup)
        .task { await vm.load(matchId: match.id) }
    }

    // MARK: - Sub-views

    private var inningsPicker: some View {
        Group {
            if vm.inningsTabs.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.inningsTabs.indices, id: \.self) { i in
                            Button { vm.selectedInningsIndex = i } label: {
                                Text(abbreviatedInningsLabel(vm.inningsTabs[i]))
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(vm.selectedInningsIndex == i
                                                ? CricColors.accent : Color(.systemGray5))
                                    .foregroundStyle(vm.selectedInningsIndex == i ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func scoreHeader(innings: Innings) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(innings.totalRuns)/\(innings.totalWickets)")
                .font(.title3.weight(.black).monospacedDigit())
            Text(String(format: "%.1f ov", innings.totalOvers))
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            let rr = innings.totalOvers > 0 ? Double(innings.totalRuns) / innings.totalOvers : 0
            Text(String(format: "%.2frr", rr))
                .font(.caption2.monospacedDigit()).foregroundStyle(CricColors.accent)
        }
    }

    private func battingSection(innings: Innings) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Batting").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach((innings.batsmen ?? []).prefix(5)) { b in
                HStack {
                    Text(lastName(b.batsman))
                        .font(.caption).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(b.r ?? 0)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle((b.r ?? 0) >= 50 ? CricColors.odi : .primary)
                    Text("(\(b.b ?? 0))")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func bowlingSection(innings: Innings) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bowling").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach((innings.bowlers ?? []).prefix(3)) { b in
                HStack {
                    Text(lastName(b.bowler))
                        .font(.caption).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(b.w ?? 0)/\(b.r ?? 0)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle((b.w ?? 0) >= 3 ? CricColors.accent : .primary)
                    Text(b.eco ?? "-")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var fallbackScores: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(match.score ?? [], id: \.inning) { s in
                HStack {
                    Text(s.inning ?? "-").font(.caption).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(s.display).font(.caption.monospacedDigit().weight(.bold))
                }
            }
            Text(match.status).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func lastName(_ full: String?) -> String {
        full?.components(separatedBy: " ").last ?? "-"
    }

    private func abbreviatedInningsLabel(_ label: String) -> String {
        let parts = label.components(separatedBy: " ")
        guard parts.count >= 2, let number = parts.last else { return label }
        return "\(parts[0].teamAbbreviation) \(number)"
    }
}
