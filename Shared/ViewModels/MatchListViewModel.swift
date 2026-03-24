import Foundation
import SwiftUI

@MainActor
@Observable
final class MatchListViewModel {
    var matches: [Match] = []
    var isLoading = false
    var error: String?
    var selectedFilter: MatchFilter = .all
    var searchText = ""

    enum MatchFilter: String, CaseIterable {
        case all    = "All"
        case live   = "Live"
        case test   = "Test"
        case odi    = "ODI"
        case t20    = "T20"
    }

    var filteredMatches: [Match] {
        let base: [Match]
        switch selectedFilter {
        case .all:  base = matches
        case .live: base = matches.filter { $0.isLive }
        case .test: base = matches.filter { $0.matchType == "test" }
        case .odi:  base = matches.filter { $0.matchType == "odi" }
        case .t20:  base = matches.filter { $0.matchType == "t20" }
        }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.teams.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var liveCount: Int { matches.filter { $0.isLive }.count }

    func load() async {
        isLoading = true
        error = nil
        do {
            matches = try await CricketAPIService.shared.fetchCurrentMatches()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async { await load() }
}
