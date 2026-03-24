// MARK: - CricSheets API Response Models
//
// These structs mirror the JSON shapes returned by the CricPulse backend
// (backend/app/main.py). The JSONDecoder in CricSheetsAPIService is
// configured with .convertFromSnakeCase, so snake_case keys decode
// automatically (e.g. "cumulative_runs" → cumulativeRuns).
//
// Shared between iOS and watchOS targets — no platform-specific imports.

import Foundation

// ── Match search result ───────────────────────────────────────────────────────

struct CSMatch: Codable, Identifiable {
    let id:             String
    let date:           String
    let teams:          [String]
    let venue:          String?
    let matchType:      String
    let tournament:     String?
    let gender:         String
    let winner:         String?
    let result:         String
    let playerOfMatch:  [String]
    let tossWinner:     String?
    let tossDecision:   String?
}

// ── Innings summary (inside CSMatchDetail) ────────────────────────────────────

struct CSInnings: Codable, Identifiable {
    let inningsNumber: Int
    let team:          String
    let runs:          Int
    let wickets:       Int
    let overs:         Double
    let display:       String
    let declared:      Bool
    let targetRuns:    Int?

    var id: Int { inningsNumber }
}

struct CSMatchDetail: Codable, Identifiable {
    let id:            String
    let date:          String
    let teams:         [String]
    let venue:         String?
    let matchType:     String
    let tournament:    String?
    let winner:        String?
    let result:        String
    let playerOfMatch: [String]
    let innings:       [CSInnings]
}

// ── Scorecard ─────────────────────────────────────────────────────────────────

struct CSScorecardResponse: Codable {
    let batting: [CSBatter]
    let bowling: [CSBowler]
}

struct CSBatter: Codable, Identifiable {
    let batsman:    String
    let runs:       Int
    let balls:      Int
    let fours:      Int
    let sixes:      Int
    let strikeRate: Double
    let dismissal:  String?     // nil = not out

    var id: String { batsman }
}

struct CSBowler: Codable, Identifiable {
    let bowler:   String
    let overs:    String        // "4.2" format
    let maidens:  Int
    let runs:     Int
    let wickets:  Int
    let economy:  Double

    var id: String { bowler }
}

// ── Over-by-over data (for run rate chart) ────────────────────────────────────

struct CSOverPoint: Codable, Identifiable {
    let over:            Int
    let runs:            Int
    let wickets:         Int
    let cumulativeRuns:  Int

    var id: Int { over }
}

// ── Wagon wheel shots ─────────────────────────────────────────────────────────

struct CSWagonShot: Codable {
    let angle:    Double    // 0–360°, clockwise from straight
    let distance: Double    // 0–1, normalised from pitch centre
    let runs:     Int       // actual runs scored off this delivery
    let batter:   String
    let bowler:   String
    let over:     Int
    let ball:     Int
}

// ── Partnerships ──────────────────────────────────────────────────────────────

struct CSPartnership: Codable, Identifiable {
    let batter1:  String
    let batter2:  String
    let runs:     Int
    let balls:    Int
    let endedBy:  String?   // dismissal kind, nil = innings ended / still batting

    var id: String { "\(batter1)+\(batter2)" }
}

// ── Fall of wickets ───────────────────────────────────────────────────────────

struct CSFoW: Codable, Identifiable {
    let wicket:    Int
    let playerOut: String?
    let runs:      Int
    let over:      String   // "14.3" format
    let kind:      String?
    let bowler:    String

    var id: Int { wicket }
}
