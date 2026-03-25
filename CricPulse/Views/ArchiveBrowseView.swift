import SwiftUI

// MARK: - Archive Browse (Year List)

struct ArchiveBrowseView: View {
    @State private var years: [String] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                CricColors.surface.ignoresSafeArea()
                Group {
                    if isLoading {
                        ProgressView("Loading archive…").tint(CricColors.accent)
                    } else if let error {
                        ErrorView(message: error) { await loadYears() }
                    } else {
                        List(years, id: \.self) { year in
                            NavigationLink(destination: ArchiveYearView(year: year)) {
                                HStack {
                                    Text(year).font(.title3.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption).foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .tint(CricColors.accent)
            .task { await loadYears() }
            .refreshable { await loadYears() }
        }
    }

    private func loadYears() async {
        isLoading = true; error = nil
        do { years = try await CricSheetsAPIService.shared.fetchYears() }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

// MARK: - Year Match List

struct ArchiveYearView: View {
    let year: String
    @State private var matches: [CSMatch] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var error: String?
    @State private var searchText = ""

    private let pageSize = 50

    var filtered: [CSMatch] {
        guard !searchText.isEmpty else { return matches }
        return matches.filter {
            $0.teams.joined().localizedCaseInsensitiveContains(searchText) ||
            ($0.tournament ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            CricColors.surface.ignoresSafeArea()
            Group {
                if isLoading && matches.isEmpty {
                    ProgressView("Loading \(year) matches…").tint(CricColors.accent)
                } else if let error, matches.isEmpty {
                    ErrorView(message: error) { await load(reset: true) }
                } else {
                    matchList
                }
            }
        }
        .navigationTitle(year)
        .navigationBarTitleDisplayMode(.large)
        .tint(CricColors.accent)
        .searchable(text: $searchText, prompt: "Search teams or tournament")
        .task { await load(reset: true) }
    }

    private var matchList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("\(total) matches")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ForEach(filtered) { match in
                    NavigationLink(destination: CSMatchDetailView(matchId: match.id, match: match)) {
                        CSMatchCard(match: match).padding(.horizontal).padding(.bottom, 10)
                    }
                    .buttonStyle(.plain)
                }

                if matches.count < total {
                    Button {
                        Task { await load(reset: false) }
                    } label: {
                        if isLoading {
                            ProgressView().tint(CricColors.accent)
                        } else {
                            Text("Load more")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CricColors.accent)
                        }
                    }
                    .padding()
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func load(reset: Bool) async {
        if reset { matches = []; total = 0 }
        isLoading = true; error = nil
        do {
            let page = try await CricSheetsAPIService.shared.fetchMatches(
                year: year, offset: matches.count, limit: pageSize
            )
            total = page.total
            matches += page.matches
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - CS Match Card

struct CSMatchCard: View {
    let match: CSMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(typeColor)
                .frame(maxWidth: .infinity, height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                // Teams + scores
                if let innings = match.innings, !innings.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(innings.prefix(2)) { inn in
                            HStack {
                                Text(inn.team.teamFlag + " " + inn.team.teamAbbreviation)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(match.winner == nil || match.winner == inn.team ? .primary : .secondary)
                                Spacer()
                                Text(inn.display)
                                    .font(.subheadline.monospacedDigit().weight(
                                        match.winner == nil || match.winner == inn.team ? .black : .regular
                                    ))
                                    .foregroundStyle(match.winner == nil || match.winner == inn.team ? .primary : .secondary)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Text((match.teams.first ?? "").teamFlag + " " + (match.teams.first ?? "").teamAbbreviation)
                            .font(.subheadline.weight(.black))
                        Text("vs").font(.caption).foregroundStyle(.tertiary)
                        Text((match.teams.count > 1 ? match.teams[1] : "").teamFlag + " " + (match.teams.count > 1 ? match.teams[1] : "").teamAbbreviation)
                            .font(.subheadline.weight(.black))
                    }
                }

                // Result + date
                HStack {
                    Text(match.result.isEmpty ? match.matchType.uppercased() : match.result)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Spacer()
                    Text(String(match.date.prefix(10)))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
        }
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var typeColor: Color {
        switch match.matchType.uppercased() {
        case "T20", "IT20": return CricColors.t20
        case "ODI", "ODM":  return CricColors.odi
        case "TEST", "MDM": return CricColors.test
        default:            return CricColors.accent
        }
    }
}

// MARK: - CS Match Detail View

@MainActor
@Observable
final class CSMatchDetailViewModel {
    var detail: CSMatchDetail?
    var isLoading = false
    var error: String?

    var selectedInningsIndex = 0
    var analyticsLoading = false

    var scorecards:   [Int: CSScorecardResponse] = [:]
    var overs:        [Int: [CSOverPoint]]        = [:]
    var wagonShots:   [Int: [WagonWheelShot]]     = [:]
    var partnerships: [Int: [CSPartnership]]      = [:]
    var fow:          [Int: [CSFoW]]              = [:]

    var selectedInnings: CSInnings? {
        guard let innings = detail?.innings,
              innings.indices.contains(selectedInningsIndex)
        else { return nil }
        return innings[selectedInningsIndex]
    }

    func load(matchId: String) async {
        isLoading = true; error = nil
        do { detail = try await CricSheetsAPIService.shared.fetchMatchDetail(matchId: matchId) }
        catch { self.error = error.localizedDescription }
        isLoading = false
        if detail != nil { await loadAnalytics(matchId: matchId, n: selectedInningsIndex + 1) }
    }

    func selectInnings(_ index: Int, matchId: String) async {
        selectedInningsIndex = index
        await loadAnalytics(matchId: matchId, n: index + 1)
    }

    private func loadAnalytics(matchId: String, n: Int) async {
        guard scorecards[n] == nil else { return }   // already cached
        analyticsLoading = true
        do {
            async let sc   = CricSheetsAPIService.shared.fetchScorecard(matchId: matchId, innings: n)
            async let ov   = CricSheetsAPIService.shared.fetchOvers(matchId: matchId, innings: n)
            async let ww   = CricSheetsAPIService.shared.fetchWagonWheel(matchId: matchId, innings: n)
            async let pts  = CricSheetsAPIService.shared.fetchPartnerships(matchId: matchId, innings: n)
            async let fowD = CricSheetsAPIService.shared.fetchFoW(matchId: matchId, innings: n)

            let (sc_, ov_, ww_, pts_, fow_) = try await (sc, ov, ww, pts, fowD)
            scorecards[n]   = sc_
            overs[n]        = ov_
            wagonShots[n]   = ww_.map { WagonWheelShot(angle: $0.angle, distance: $0.distance,
                                                        runs: $0.runs, batsmanName: $0.batter) }
            partnerships[n] = pts_
            fow[n]          = fow_
        } catch { /* non-fatal */ }
        analyticsLoading = false
    }
}

struct CSMatchDetailView: View {
    let matchId: String
    let match: CSMatch
    @State private var vm = CSMatchDetailViewModel()

    var body: some View {
        ZStack {
            CricColors.surface.ignoresSafeArea()
            if vm.isLoading && vm.detail == nil {
                ProgressView("Loading scorecard…").tint(CricColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error, vm.detail == nil {
                ErrorView(message: error) { await vm.load(matchId: matchId) }
            } else {
                content
            }
        }
        .navigationTitle(
            (match.teams.first?.teamAbbreviation ?? "") + " vs " +
            (match.teams.count > 1 ? match.teams[1].teamAbbreviation : "")
        )
        .navigationBarTitleDisplayMode(.inline)
        .tint(CricColors.accent)
        .task { await vm.load(matchId: matchId) }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Match result banner
                if !match.result.isEmpty {
                    HStack {
                        Image(systemName: "trophy.fill").foregroundStyle(CricColors.t20)
                        Text(match.result).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        if let pom = match.playerOfMatch.first {
                            Text("⭐ \(pom)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(CricColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
                }

                // Innings picker
                if let innings = vm.detail?.innings, innings.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(innings.indices, id: \.self) { i in
                                Button {
                                    Task { await vm.selectInnings(i, matchId: matchId) }
                                } label: {
                                    Text(innings[i].team.teamAbbreviation)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(vm.selectedInningsIndex == i ? CricColors.accent : Color(.systemGray6))
                                        .foregroundStyle(vm.selectedInningsIndex == i ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                if let inn = vm.selectedInnings {
                    let n = vm.selectedInningsIndex + 1

                    // Score header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(inn.team).font(.caption).foregroundStyle(.secondary)
                            Text("\(inn.runs)/\(inn.wickets)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                            Text(String(format: "%.1f overs", inn.overs))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Run Rate").font(.caption).foregroundStyle(.secondary)
                            let rr = inn.overs > 0 ? Double(inn.runs) / inn.overs : 0
                            Text(String(format: "%.2f", rr))
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundStyle(CricColors.accent)
                        }
                    }
                    .padding(16)
                    .background(CricColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))

                    if vm.analyticsLoading && vm.scorecards[n] == nil {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.7)
                            Text("Loading ball-by-ball analytics…")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Scorecard
                    if let sc = vm.scorecards[n] {
                        CSBattingView(batting: sc.batting)
                        CSBowlingView(bowling: sc.bowling)
                    }

                    // Charts + analytics
                    WagonWheelView(shots: vm.wagonShots[n] ?? [])

                    let overData = (vm.overs[n] ?? []).map {
                        OverData(over: $0.over, runs: $0.runs, cumulativeRuns: $0.cumulativeRuns,
                                 wickets: $0.wickets, inningsLabel: inn.team)
                    }
                    RunRateChartView(data: overData)

                    if let parts = vm.partnerships[n], !parts.isEmpty {
                        PartnershipsView(partnerships: parts)
                    }
                    if let fowData = vm.fow[n], !fowData.isEmpty {
                        FallOfWicketsView(fow: fowData)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - CS Batting + Bowling tables (CricSheets-native)

private struct CSBattingView: View {
    let batting: [CSBatter]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Batting").font(.headline.weight(.bold))
            HStack {
                Text("Batsman").frame(maxWidth: .infinity, alignment: .leading)
                Text("R").frame(width: 36, alignment: .trailing)
                Text("B").frame(width: 36, alignment: .trailing)
                Text("4s").frame(width: 28, alignment: .trailing)
                Text("6s").frame(width: 28, alignment: .trailing)
                Text("SR").frame(width: 48, alignment: .trailing)
            }
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Divider()
            ForEach(batting) { b in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.batsman).font(.subheadline.weight(.medium))
                        if let d = b.dismissal {
                            Text(d).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(b.runs)").frame(width: 36, alignment: .trailing)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(b.runs >= 50 ? CricColors.odi : .primary)
                    Text("\(b.balls)").frame(width: 36, alignment: .trailing)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Text("\(b.fours)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(b.sixes)").frame(width: 28, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(b.sixes > 0 ? CricColors.t20 : .primary)
                    Text(String(format: "%.1f", b.strikeRate)).frame(width: 48, alignment: .trailing)
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

private struct CSBowlingView: View {
    let bowling: [CSBowler]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bowling").font(.headline.weight(.bold))
            HStack {
                Text("Bowler").frame(maxWidth: .infinity, alignment: .leading)
                Text("O").frame(width: 32, alignment: .trailing)
                Text("M").frame(width: 24, alignment: .trailing)
                Text("R").frame(width: 32, alignment: .trailing)
                Text("W").frame(width: 24, alignment: .trailing)
                Text("Eco").frame(width: 40, alignment: .trailing)
            }
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Divider()
            ForEach(bowling) { b in
                HStack {
                    Text(b.bowler).font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(b.overs).frame(width: 32, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(b.maidens)").frame(width: 24, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(b.runs)").frame(width: 32, alignment: .trailing)
                        .font(.caption.monospacedDigit())
                    Text("\(b.wickets)").frame(width: 24, alignment: .trailing)
                        .font(.subheadline.weight(.black).monospacedDigit())
                        .foregroundStyle(b.wickets >= 3 ? CricColors.accent : .primary)
                    Text(String(format: "%.2f", b.economy)).frame(width: 40, alignment: .trailing)
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
