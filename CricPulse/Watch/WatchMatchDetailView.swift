import SwiftUI

// MARK: - Match Detail (watch)
//
// Compact scorecard: innings selector → batting top-5 + bowling top-3.
// No charts or wagon wheel — watch screen too small, battery too precious.
// CricSheets enrichment (loadCricSheetsData) is intentionally NOT called:
// the backend runs on localhost and is unreachable from a physical watch.

struct WatchMatchDetailView: View {
    let match: Match
    @State private var vm = MatchDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                // Status
                if match.isLive {
                    HStack(spacing: 5) {
                        Circle().fill(CricColors.live).frame(width: 6, height: 6)
                        Text("LIVE").font(.caption2.weight(.black)).foregroundStyle(CricColors.live)
                    }
                }

                if vm.isLoading && vm.scorecard == nil {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let innings = vm.selectedInnings {
                    // Innings picker (scrollable chips)
                    if vm.inningsTabs.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vm.inningsTabs.indices, id: \.self) { i in
                                    Button { vm.selectedInningsIndex = i } label: {
                                        Text(shortInningsLabel(vm.inningsTabs[i]))
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(vm.selectedInningsIndex == i
                                                        ? CricColors.accent
                                                        : Color(.systemGray5))
                                            .foregroundStyle(vm.selectedInningsIndex == i ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Score headline
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(innings.totalRuns)/\(innings.totalWickets)")
                            .font(.title3.weight(.black).monospacedDigit())
                        Text(String(format: "%.1f ov", innings.totalOvers))
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        let rr = innings.totalOvers > 0
                            ? Double(innings.totalRuns) / innings.totalOvers : 0
                        Text(String(format: "%.2f rr", rr))
                            .font(.caption2.monospacedDigit()).foregroundStyle(CricColors.accent)
                    }

                    Divider()

                    // Top batsmen
                    Group {
                        Text("Batting").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        ForEach((innings.batsmen ?? []).prefix(5)) { b in
                            HStack {
                                Text(lastName(b.batsman))
                                    .font(.caption).lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(b.r ?? 0)")
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .foregroundStyle((b.r ?? 0) >= 50 ? CricColors.odi : .primary)
                                Text("(\(b.b ?? 0))")
                                    .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Top bowlers
                    Group {
                        Text("Bowling").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        ForEach((innings.bowlers ?? []).prefix(3)) { b in
                            HStack {
                                Text(lastName(b.bowler))
                                    .font(.caption).lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(b.w ?? 0)/\(b.r ?? 0)")
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .foregroundStyle((b.w ?? 0) >= 3 ? CricColors.accent : .primary)
                                Text(b.eco ?? "-")
                                    .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else if vm.scorecard == nil && !vm.isLoading {
                    // Fallback: no scorecard — show summary scores
                    if let scores = match.score, !scores.isEmpty {
                        ForEach(scores, id: \.inning) { s in
                            HStack {
                                Text(s.inning ?? "-").font(.caption).lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(s.display).font(.caption.monospacedDigit().weight(.bold))
                            }
                        }
                    }
                    Text(match.status).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(match.shortMatchup)
        .task { await vm.load(matchId: match.id) }
    }

    private func lastName(_ full: String?) -> String {
        full?.components(separatedBy: " ").last ?? "-"
    }

    private func shortInningsLabel(_ label: String) -> String {
        // "India Inning 1" → "IND 1"
        let parts = label.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].teamAbbreviation) \(parts.last ?? "")"
        }
        return label
    }
}
