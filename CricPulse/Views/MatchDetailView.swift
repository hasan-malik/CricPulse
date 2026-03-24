import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @State private var vm = MatchDetailViewModel()

    var body: some View {
        ZStack {
            CricColors.surface.ignoresSafeArea()

            if vm.isLoading && vm.scorecard == nil {
                ProgressView("Loading scorecard…")
                    .tint(CricColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error, vm.scorecard == nil {
                ErrorView(message: error) { await vm.load(matchId: match.id) }
            } else {
                content
            }
        }
        .navigationTitle(match.team1 + " vs " + match.team2)
        .navigationBarTitleDisplayMode(.inline)
        .tint(CricColors.accent)
        .task {
            await vm.load(matchId: match.id)
            if match.isLive { vm.startAutoRefresh(matchId: match.id) }
        }
        .onDisappear { vm.stopAutoRefresh() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                statusBanner

                let hasInnings = !(vm.scorecard?.innings?.isEmpty ?? true)

                if hasInnings {
                    if vm.inningsTabs.count > 1 {
                        inningsPicker
                    }
                    if let innings = vm.selectedInnings {
                        scoreSummaryCard(innings: innings)
                        BatsmenView(innings: innings)
                        BowlersView(innings: innings)
                    }
                } else {
                    // Fallback: show summary from match list data
                    resultSummaryCard
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        HStack {
            if match.isLive { LiveBadge() }
            Text(match.status)
                .font(.subheadline)
                .foregroundStyle(match.isLive ? CricColors.live : .secondary)
                .lineLimit(3)
            Spacer()
        }
        .padding(14)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }

    // MARK: - Innings Picker

    private var inningsPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.inningsTabs.indices, id: \.self) { i in
                    Button {
                        vm.selectedInningsIndex = i
                    } label: {
                        Text(vm.inningsTabs[i])
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(vm.selectedInningsIndex == i
                                ? CricColors.accent
                                : Color(.systemGray6))
                            .foregroundStyle(vm.selectedInningsIndex == i ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Score Summary Card

    private func scoreSummaryCard(innings: Innings) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(innings.inning ?? "Innings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(innings.totalRuns)/\(innings.totalWickets)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                Text(String(format: "%.1f overs", innings.totalOvers))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Run Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let rr = innings.totalOvers > 0
                    ? Double(innings.totalRuns) / innings.totalOvers
                    : 0.0
                Text(String(format: "%.2f", rr))
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(CricColors.accent)
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }

    // MARK: - Result Summary Fallback

    private var resultSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(CricColors.t20)
                Text("Match Summary")
                    .font(.headline.weight(.bold))
                Spacer()
            }

            if let scores = match.score, !scores.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(scores.enumerated()), id: \.element.inning) { idx, score in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(score.inning ?? "Innings \(idx + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(score.display)
                                .font(.title3.weight(.black).monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 10)
                        if idx < scores.count - 1 {
                            Divider()
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Ball-by-ball scorecard available for live matches and select series on the free API tier.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }
}

// MARK: - Batsmen Table

struct BatsmenView: View {
    let innings: Innings
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Batting")
                    .font(.headline.weight(.bold))
                Spacer()
            }

            HStack {
                Text("Batsman").frame(maxWidth: .infinity, alignment: .leading)
                Text("R").frame(width: 36, alignment: .trailing)
                Text("B").frame(width: 36, alignment: .trailing)
                Text("4s").frame(width: 28, alignment: .trailing)
                Text("6s").frame(width: 28, alignment: .trailing)
                Text("SR").frame(width: 48, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Divider()

            ForEach(innings.batsmen ?? []) { batsman in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(batsman.batsman ?? "-")
                            .font(.subheadline.weight(.medium))
                        if let d = batsman.dismissal {
                            Text(d)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(batsman.r ?? 0)").frame(width: 36, alignment: .trailing)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle((batsman.r ?? 0) >= 50 ? CricColors.odi : .primary)
                    Text("\(batsman.b ?? 0)").frame(width: 36, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Text("\(batsman.fours ?? 0)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(batsman.sixes ?? 0)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle((batsman.sixes ?? 0) > 0 ? CricColors.t20 : .primary)
                    Text(batsman.strikeRate ?? "-").frame(width: 48, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Divider()
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }
}

// MARK: - Bowlers Table

struct BowlersView: View {
    let innings: Innings
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bowling")
                .font(.headline.weight(.bold))

            HStack {
                Text("Bowler").frame(maxWidth: .infinity, alignment: .leading)
                Text("O").frame(width: 32, alignment: .trailing)
                Text("M").frame(width: 24, alignment: .trailing)
                Text("R").frame(width: 32, alignment: .trailing)
                Text("W").frame(width: 24, alignment: .trailing)
                Text("Eco").frame(width: 40, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Divider()

            ForEach(innings.bowlers ?? []) { bowler in
                HStack {
                    Text(bowler.bowler ?? "-")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bowler.o ?? "-").frame(width: 32, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(bowler.m ?? 0)").frame(width: 24, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(bowler.r ?? 0)").frame(width: 32, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(bowler.w ?? 0)").frame(width: 24, alignment: .trailing)
                        .font(.subheadline.weight(.black).monospacedDigit())
                        .foregroundStyle((bowler.w ?? 0) >= 3 ? CricColors.accent : .primary)
                    Text(bowler.eco ?? "-").frame(width: 40, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Divider()
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }
}
