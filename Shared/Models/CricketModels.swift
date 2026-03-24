import Foundation
import SwiftData

// MARK: - API Response Wrapper

struct APIResponse<T: Codable>: Codable {
    let status: String
    let data: T?
    let info: APIInfo?
}

struct APIInfo: Codable {
    let hitsToday: Int?
    let hitsUsed: Int?
    let hitsLimit: Int?
}

// MARK: - Match

struct Match: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let matchType: String       // "test", "odi", "t20", "t10", "custom"
    let status: String
    let venue: String?
    let date: String?
    let dateTimeGMT: String?
    let teams: [String]
    let teamInfo: [TeamInfo]?
    let score: [InningsScore]?
    let seriesId: String?
    let matchStarted: Bool?
    let matchEnded: Bool?

    var isLive: Bool {
        (matchStarted == true) && (matchEnded == false)
    }

    var shortStatus: String {
        if isLive { return "LIVE" }
        if matchEnded == true { return "Completed" }
        return "Upcoming"
    }

    var team1: String { teams.first ?? "TBA" }
    var team2: String { teams.count > 1 ? teams[1] : "TBA" }
}

// MARK: - Team Info

struct TeamInfo: Codable, Hashable {
    let name: String
    let shortname: String?
    let img: String?
}

// MARK: - Innings Score (summary on match list)

struct InningsScore: Codable, Hashable {
    let r: Int?         // runs
    let w: Int?         // wickets
    let o: Double?      // overs
    let inning: String? // "India Inning 1"

    var display: String {
        guard let r, let w, let o else { return "-" }
        return "\(r)/\(w) (\(String(format: "%.1f", o)) ov)"
    }
}

// MARK: - Full Scorecard

struct Scorecard: Codable {
    let id: String
    let name: String?
    let matchType: String?
    let status: String?
    let venue: String?
    let date: String?
    let teams: [String]?
    let teamInfo: [TeamInfo]?
    let score: [InningsScore]?
    let innings: [Innings]?
    let matchStarted: Bool?
    let matchEnded: Bool?
}

// MARK: - Innings (full batting + bowling)

struct Innings: Codable, Identifiable {
    var id: String { inning ?? UUID().uuidString }
    let inning: String?
    let battingTeam: String?
    let batsmen: [Batsman]?
    let bowlers: [Bowler]?
    let extras: Extras?
    let total: InningsTotal?

    // Computed for wagon wheel / charts
    var totalRuns: Int { total?.r ?? 0 }
    var totalWickets: Int { total?.w ?? 0 }
    var totalOvers: Double { total?.o ?? 0.0 }
}

// MARK: - Batsman

struct Batsman: Codable, Identifiable, Hashable {
    var id: String { batsman ?? UUID().uuidString }
    let batsman: String?
    let dismissal: String?
    let r: Int?     // runs
    let b: Int?     // balls
    let fours: Int?
    let sixes: Int?
    let strikeRate: String?

    var strikeRateDouble: Double {
        Double(strikeRate ?? "0") ?? 0.0
    }
}

// MARK: - Bowler

struct Bowler: Codable, Identifiable, Hashable {
    var id: String { bowler ?? UUID().uuidString }
    let bowler: String?
    let o: String?   // overs bowled
    let m: Int?      // maidens
    let r: Int?      // runs given
    let w: Int?      // wickets
    let eco: String? // economy

    var economyDouble: Double {
        Double(eco ?? "0") ?? 0.0
    }
}

// MARK: - Extras & Total

struct Extras: Codable {
    let r: Int?
    let b: Int?
    let lb: Int?
    let wd: Int?
    let nb: Int?
    let p: Int?
}

struct InningsTotal: Codable {
    let r: Int?
    let w: Int?
    let o: Double?
    let inning: String?
}

// MARK: - Wagon Wheel Data Point

struct WagonWheelShot: Identifiable {
    let id = UUID()
    let angle: Double       // 0–360 degrees around the pitch
    let distance: Double    // 0–1, normalised distance from centre
    let runs: Int           // 0, 1, 2, 3, 4, 6
    let batsmanName: String
}

// MARK: - Run Rate Data Point (for Swift Charts)

struct OverData: Identifiable {
    let id = UUID()
    let over: Int
    let runs: Int
    let cumulativeRuns: Int
    let wickets: Int
    let inningsLabel: String
}

// MARK: - SwiftData: Favourites

@Model
final class FavouriteTeam {
    var name: String
    var shortname: String
    var logoURL: String?
    var addedAt: Date

    init(name: String, shortname: String, logoURL: String? = nil) {
        self.name = name
        self.shortname = shortname
        self.logoURL = logoURL
        self.addedAt = Date()
    }
}

@Model
final class RecentlyViewedMatch {
    var matchId: String
    var matchName: String
    var status: String
    var viewedAt: Date

    init(matchId: String, matchName: String, status: String) {
        self.matchId = matchId
        self.matchName = matchName
        self.status = status
        self.viewedAt = Date()
    }
}
