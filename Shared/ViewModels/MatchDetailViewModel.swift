import Foundation
import SwiftUI

@MainActor
@Observable
final class MatchDetailViewModel {

    // MARK: - CricAPI state

    var scorecard: Scorecard?
    var match: Match?
    var isLoading = false
    var error: String?
    var selectedInningsIndex = 0
    var autoRefreshTask: Task<Void, Never>?

    var selectedInnings: Innings? {
        guard let innings = scorecard?.innings,
              innings.indices.contains(selectedInningsIndex)
        else { return nil }
        return innings[selectedInningsIndex]
    }

    var inningsTabs: [String] {
        scorecard?.innings?.compactMap { $0.inning } ?? []
    }

    // MARK: - CricSheets enrichment state

    var csMatchId: String?                      // CricSheets numeric match ID
    var csIsLoading = false
    var csOverData:       [OverData]         = []
    var csWagonShots:     [WagonWheelShot]   = []   // converted from CSWagonShot
    var csPartnerships:   [CSPartnership]    = []
    var csFoW:            [CSFoW]            = []

    /// True once the backend has confirmed a match and returned analytics data.
    var hasCricSheetsData: Bool {
        csMatchId != nil && !csOverData.isEmpty
    }

    // MARK: - CricAPI load

    func load(matchId: String) async {
        isLoading = true
        error = nil
        do {
            async let scorecardTask = CricketAPIService.shared.fetchScorecard(matchId: matchId)
            async let matchTask     = CricketAPIService.shared.fetchMatchInfo(matchId: matchId)
            (scorecard, match) = try await (scorecardTask, matchTask)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Auto-refresh (live matches)

    func startAutoRefresh(matchId: String, interval: TimeInterval = 30) {
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                if !Task.isCancelled { await load(matchId: matchId) }
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    // MARK: - CricSheets enrichment

    /// Resolves the CricSheets match ID from teams + date, then loads analytics.
    /// Silently no-ops if the backend is unreachable or the match isn't in the DB yet.
    func loadCricSheetsData(for match: Match) async {
        guard csMatchId == nil else { return }   // already resolved this session
        csIsLoading = true
        defer { csIsLoading = false }

        let date = String((match.dateTimeGMT ?? match.date ?? "").prefix(10))
        do {
            let result = try await CricSheetsAPIService.shared.searchMatch(
                team1:  match.team1,
                team2:  match.team2,
                date:   date,
                format: match.matchType
            )
            csMatchId = result.id
            await reloadCricSheetsInnings()
        } catch CricSheetsError.notFound {
            // Match not in our DB yet — this is expected for recent/live matches
        } catch {
            // Backend unreachable — silently degrade
        }
    }

    /// Re-fetches all analytics for the currently selected innings.
    /// Called on innings tab change.
    func reloadCricSheetsInnings() async {
        guard let id = csMatchId else { return }
        let n = selectedInningsIndex + 1   // backend is 1-indexed
        csIsLoading = true
        defer { csIsLoading = false }

        do {
            async let oversTask   = CricSheetsAPIService.shared.fetchOvers(matchId: id, innings: n)
            async let wagonTask   = CricSheetsAPIService.shared.fetchWagonWheel(matchId: id, innings: n)
            async let partsTask   = CricSheetsAPIService.shared.fetchPartnerships(matchId: id, innings: n)
            async let fowTask     = CricSheetsAPIService.shared.fetchFoW(matchId: id, innings: n)

            let (overs, wagon, parts, fow) = try await (oversTask, wagonTask, partsTask, fowTask)

            let label = selectedInnings?.inning ?? "Innings \(n)"
            csOverData = overs.map {
                OverData(over: $0.over, runs: $0.runs, cumulativeRuns: $0.cumulativeRuns,
                         wickets: $0.wickets, inningsLabel: label)
            }
            csWagonShots = wagon.map {
                WagonWheelShot(angle: $0.angle, distance: $0.distance,
                               runs: $0.runs, batsmanName: $0.batter)
            }
            csPartnerships = parts
            csFoW          = fow
        } catch {
            // Non-fatal — keep existing data from previous innings load
        }
    }

    // MARK: - Synthetic fallbacks (used when CricSheets data unavailable)

    func overData(for innings: Innings) -> [OverData] {
        guard let total = innings.total,
              let totalRuns = total.r,
              let totalOvers = total.o,
              totalOvers > 0
        else { return [] }

        let overCount = Int(ceil(totalOvers))
        var cumulative = 0
        return (1...overCount).map { over in
            let progress = Double(over) / totalOvers
            let expected = Int(Double(totalRuns) * progress)
            let runsThisOver = max(0, expected - cumulative)
            cumulative = expected
            return OverData(over: over, runs: runsThisOver, cumulativeRuns: cumulative,
                            wickets: 0,
                            inningsLabel: innings.inning ?? "Innings \(selectedInningsIndex + 1)")
        }
    }

    func wagonWheelShots(for innings: Innings) -> [WagonWheelShot] {
        guard let batsmen = innings.batsmen else { return [] }
        var shots: [WagonWheelShot] = []
        for batsman in batsmen {
            guard let runs = batsman.r, runs > 0 else { continue }
            let fours   = batsman.fours ?? 0
            let sixes   = batsman.sixes ?? 0
            let singles = max(0, runs - fours * 4 - sixes * 6)
            let base    = Double.random(in: 0...360)
            for _ in 0..<fours {
                shots.append(WagonWheelShot(
                    angle:       (base + Double.random(in: -45...45)).truncatingRemainder(dividingBy: 360),
                    distance:    Double.random(in: 0.7...1.0),
                    runs:        4,
                    batsmanName: batsman.batsman ?? "Unknown"))
            }
            for _ in 0..<sixes {
                shots.append(WagonWheelShot(
                    angle:       (base + Double.random(in: -60...60)).truncatingRemainder(dividingBy: 360),
                    distance:    1.0,
                    runs:        6,
                    batsmanName: batsman.batsman ?? "Unknown"))
            }
            let sBase = (base + 90).truncatingRemainder(dividingBy: 360)
            for _ in 0..<min(singles, 15) {
                shots.append(WagonWheelShot(
                    angle:       (sBase + Double.random(in: -70...70)).truncatingRemainder(dividingBy: 360),
                    distance:    Double.random(in: 0.2...0.6),
                    runs:        1,
                    batsmanName: batsman.batsman ?? "Unknown"))
            }
        }
        return shots
    }

    // MARK: - Unified accessors (prefer CricSheets, fall back to synthetic)

    func effectiveOverData(for innings: Innings) -> [OverData] {
        hasCricSheetsData ? csOverData : overData(for: innings)
    }

    func effectiveWagonShots(for innings: Innings) -> [WagonWheelShot] {
        hasCricSheetsData ? csWagonShots : wagonWheelShots(for: innings)
    }
}
