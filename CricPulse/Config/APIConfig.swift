import Foundation

enum APIConfig {
    static let apiKey = "746cb531-1681-4cf4-978f-f677a81104e5"
    static let baseURL = "https://api.cricapi.com/v1"

    enum Endpoint {
        static let currentMatches = "\(baseURL)/currentMatches"
        static let matchInfo      = "\(baseURL)/match_info"
        static let scorecard      = "\(baseURL)/match_scorecard"
        static let series         = "\(baseURL)/series"
        static let seriesInfo     = "\(baseURL)/series_info"
        static let players        = "\(baseURL)/players"
        static let playerInfo     = "\(baseURL)/players_info"
    }
}
