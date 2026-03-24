import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @State private var vm = MatchDetailViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if vm.isLoading && vm.scorecard == nil {
                ProgressView("Loading scorecard…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error, vm.scorecard == nil {
                ErrorView(message: error) { await vm.load(matchId: match.id) }
            } else {
                content
            }
        }
        .navigationTitle(match.team1 + " vs " + match.team2)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load(matchId: match.id)
            if match.isLive { vm.startAutoRefresh(matchId: match.id) }
        }
        .onDisappear { vm.stopAutoRefresh() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status banner
                statusBanner

                // Innings tabs
                if vm.inningsTabs.count > 1 {
                    inningsPicker
                }

                // Score summary
                if let innings = vm.selectedInnings {
                    scoreSummaryCard(innings: innings)
                    WagonWheelView(shots: vm.wagonWheelShots(for: innings))
                    RunRateChartView(overData: vm.overData(for: innings))
                    BatsmenView(innings: innings)
                    BowlersView(innings: innings)
                }
            }
            .padding()
        }
    }

    private var statusBanner: some View {
        HStack {
            if match.isLive { LiveBadge() }
            Text(match.status)
                .font(.subheadline)
                .foregroundStyle(match.isLive ? .primary : .secondary)
            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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
                                ? Color.accentColor
                                : Color(.secondarySystemBackground))
                            .foregroundStyle(vm.selectedInningsIndex == i ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func scoreSummaryCard(innings: Innings) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(innings.inning ?? "Innings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(innings.totalRuns)/\(innings.totalWickets)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                Text(String(format: "%.1f overs", innings.totalOvers))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Run rate
            VStack(alignment: .trailing, spacing: 4) {
                Text("Run Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let rr = innings.totalOvers > 0
                    ? Double(innings.totalRuns) / innings.totalOvers
                    : 0.0
                Text(String(format: "%.2f", rr))
                    .font(.title2.weight(.bold).monospacedDigit())
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Batsmen Table

struct BatsmenView: View {
    let innings: Innings
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Batting")
                .font(.headline)
                .padding(.bottom, 2)

            // Header
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
                        .font(.subheadline.monospacedDigit())
                    Text("\(batsman.b ?? 0)").frame(width: 36, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Text("\(batsman.fours ?? 0)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(batsman.sixes ?? 0)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text(batsman.strikeRate ?? "-").frame(width: 48, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Divider()
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Bowlers Table

struct BowlersView: View {
    let innings: Innings
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bowling")
                .font(.headline)
                .padding(.bottom, 2)

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
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(bowler.w ?? 0 >= 3 ? .orange : .primary)
                    Text(bowler.eco ?? "-").frame(width: 40, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Divider()
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
