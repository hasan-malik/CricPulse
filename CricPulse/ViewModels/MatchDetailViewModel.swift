import Foundation
import SwiftUI

@MainActor
@Observable
final class MatchDetailViewModel {
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

    // MARK: - Load

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

    // MARK: - Auto Refresh (live matches only)

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

    // MARK: - Chart Data: Runs Per Over

    func overData(for innings: Innings) -> [OverData] {
        // Parse from batsmen/extras to build over-by-over data
        // In production this comes from ball-by-ball API data
        // For now generate from total runs across overs (interpolated)
        guard let total = innings.total,
              let totalRuns = total.r,
              let totalOvers = total.o,
              totalOvers > 0
        else { return [] }

        let overCount = Int(ceil(totalOvers))
        var cumulative = 0
        return (1...overCount).map { over in
            let progress = Double(over) / totalOvers
            let expectedCumulative = Int(Double(totalRuns) * progress)
            let runsThisOver = max(0, expectedCumulative - cumulative)
            cumulative = expectedCumulative
            return OverData(
                over: over,
                runs: runsThisOver,
                cumulativeRuns: cumulative,
                wickets: 0,
                inningsLabel: innings.inning ?? "Innings \(selectedInningsIndex + 1)"
            )
        }
    }

    // MARK: - Wagon Wheel (synthetic from batsmen strike rates / runs)

    func wagonWheelShots(for innings: Innings) -> [WagonWheelShot] {
        guard let batsmen = innings.batsmen else { return [] }
        var shots: [WagonWheelShot] = []
        for batsman in batsmen {
            guard let runs = batsman.r, runs > 0 else { continue }
            let fours = batsman.fours ?? 0
            let sixes = batsman.sixes ?? 0
            let singles = max(0, runs - (fours * 4) - (sixes * 6))

            // Place shots at distributed angles (each batsman has a preferred arc)
            let baseAngle = Double.random(in: 0...360)
            for _ in 0..<fours {
                shots.append(WagonWheelShot(
                    angle: (baseAngle + Double.random(in: -45...45)).truncatingRemainder(dividingBy: 360),
                    distance: Double.random(in: 0.7...1.0),
                    runs: 4,
                    batsmanName: batsman.batsman ?? "Unknown"
                ))
            }
            for _ in 0..<sixes {
                shots.append(WagonWheelShot(
                    angle: (baseAngle + Double.random(in: -60...60)).truncatingRemainder(dividingBy: 360),
                    distance: 1.0,
                    runs: 6,
                    batsmanName: batsman.batsman ?? "Unknown"
                ))
            }
            let singleAngle = (baseAngle + 90).truncatingRemainder(dividingBy: 360)
            for _ in 0..<min(singles, 15) {
                shots.append(WagonWheelShot(
                    angle: (singleAngle + Double.random(in: -70...70)).truncatingRemainder(dividingBy: 360),
                    distance: Double.random(in: 0.2...0.6),
                    runs: 1,
                    batsmanName: batsman.batsman ?? "Unknown"
                ))
            }
        }
        return shots
    }
}
