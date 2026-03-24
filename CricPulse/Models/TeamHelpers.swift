import Foundation

// MARK: - Team Name → Abbreviation

extension String {
    var teamAbbreviation: String {
        let map: [String: String] = [
            // International
            "India": "IND", "Pakistan": "PAK", "Australia": "AUS",
            "New Zealand": "NZ", "South Africa": "SA", "England": "ENG",
            "West Indies": "WI", "Sri Lanka": "SL", "Bangladesh": "BAN",
            "Afghanistan": "AFG", "Zimbabwe": "ZIM", "Ireland": "IRE",
            "Scotland": "SCO", "Netherlands": "NED", "Namibia": "NAM",
            "Nepal": "NEP", "Oman": "OMA", "Papua New Guinea": "PNG",
            "United Arab Emirates": "UAE", "UAE": "UAE",
            "Canada": "CAN", "USA": "USA", "United States of America": "USA",
            "Kenya": "KEN", "Hong Kong": "HK",
            // IPL
            "Mumbai Indians": "MI", "Chennai Super Kings": "CSK",
            "Royal Challengers Bangalore": "RCB", "Royal Challengers Bengaluru": "RCB",
            "Kolkata Knight Riders": "KKR", "Delhi Capitals": "DC",
            "Punjab Kings": "PBKS", "Rajasthan Royals": "RR",
            "Sunrisers Hyderabad": "SRH", "Lucknow Super Giants": "LSG",
            "Gujarat Titans": "GT",
            // PSL
            "Karachi Kings": "KK", "Lahore Qalandars": "LQ",
            "Peshawar Zalmi": "PZ", "Quetta Gladiators": "QG",
            "Islamabad United": "IU", "Multan Sultans": "MS",
        ]
        if let abbr = map[self] { return abbr }
        // Fallback: first letters of words, up to 3 chars
        let words = self.components(separatedBy: " ").filter { !$0.isEmpty }
        if words.count == 1 { return String(self.prefix(3)).uppercased() }
        return String(words.prefix(3).compactMap { $0.first }).uppercased()
    }

    var teamFlag: String {
        let flags: [String: String] = [
            "India": "🇮🇳", "Pakistan": "🇵🇰", "Australia": "🇦🇺",
            "New Zealand": "🇳🇿", "South Africa": "🇿🇦", "England": "🇬🇧",
            "West Indies": "🌴", "Sri Lanka": "🇱🇰", "Bangladesh": "🇧🇩",
            "Afghanistan": "🇦🇫", "Zimbabwe": "🇿🇼", "Ireland": "🇮🇪",
            "Scotland": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "Netherlands": "🇳🇱", "Namibia": "🇳🇦",
            "Nepal": "🇳🇵", "Oman": "🇴🇲", "Papua New Guinea": "🇵🇬",
            "United Arab Emirates": "🇦🇪", "UAE": "🇦🇪",
            "Canada": "🇨🇦", "USA": "🇺🇸", "United States of America": "🇺🇸",
            "Kenya": "🇰🇪", "Hong Kong": "🇭🇰",
        ]
        return flags[self] ?? ""
    }
}

// MARK: - Match Helpers

extension Match {
    /// "IND vs PAK" — abbreviated team names
    var shortMatchup: String {
        let t1 = (teams.first ?? "").teamAbbreviation
        let t2 = (teams.count > 1 ? teams[1] : "").teamAbbreviation
        return "\(t1) vs \(t2)"
    }

    /// Series/context extracted from match name, e.g. "3rd ODI" from "India vs Pakistan, 3rd ODI"
    var seriesContext: String {
        if let range = name.range(of: ", ") {
            return String(name[range.upperBound...])
        }
        return matchType.uppercased()
    }
}
