import Foundation

// MARK: - Errors

enum CricSheetsError: LocalizedError {
    case invalidURL
    case notFound                       // 404 — match not in our DB yet
    case serverError(Int)
    case decodingFailed(Error)
    case networkFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "Invalid URL"
        case .notFound:            return "Match not found in CricSheets database"
        case .serverError(let c):  return "Server error \(c)"
        case .decodingFailed(let e): return "Decode failed: \(e.localizedDescription)"
        case .networkFailed(let e):  return e.localizedDescription
        }
    }
}

// MARK: - Service

actor CricSheetsAPIService {
    static let shared = CricSheetsAPIService()

    // 127.0.0.1 forces IPv4 — avoids IPv6 resolution delay on simulator
    private let baseURL = "http://127.0.0.1:8000"

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 10
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase  // snake_case → camelCase
    }

    // MARK: - Public API

    func searchMatch(team1: String, team2: String, date: String, format: String?) async throws -> CSMatch {
        var comps = URLComponents(string: baseURL + "/matches/search")!
        comps.queryItems = [
            .init(name: "team1",  value: team1),
            .init(name: "team2",  value: team2),
            .init(name: "date",   value: date),
        ]
        if let fmt = format { comps.queryItems?.append(.init(name: "format", value: fmt)) }
        return try await fetch(url: comps.url!)
    }

    func fetchMatchDetail(matchId: String) async throws -> CSMatchDetail {
        try await fetch(url: url("/matches/\(matchId)"))
    }

    func fetchScorecard(matchId: String, innings: Int) async throws -> CSScorecardResponse {
        try await fetch(url: url("/matches/\(matchId)/innings/\(innings)/scorecard"))
    }

    func fetchOvers(matchId: String, innings: Int) async throws -> [CSOverPoint] {
        try await fetch(url: url("/matches/\(matchId)/innings/\(innings)/overs"))
    }

    func fetchWagonWheel(matchId: String, innings: Int, batter: String? = nil) async throws -> [CSWagonShot] {
        var path = "/matches/\(matchId)/innings/\(innings)/wagonwheel"
        if let b = batter, let enc = b.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "?batter=\(enc)"
        }
        return try await fetch(url: url(path))
    }

    func fetchPartnerships(matchId: String, innings: Int) async throws -> [CSPartnership] {
        try await fetch(url: url("/matches/\(matchId)/innings/\(innings)/partnerships"))
    }

    func fetchFoW(matchId: String, innings: Int) async throws -> [CSFoW] {
        try await fetch(url: url("/matches/\(matchId)/innings/\(innings)/fow"))
    }

    func fetchYears() async throws -> [String] {
        struct R: Decodable { let years: [String] }
        let r: R = try await fetch(url: url("/matches/years"))
        return r.years
    }

    func fetchMatches(year: String? = nil, offset: Int = 0, limit: Int = 50) async throws -> CSMatchPage {
        var comps = URLComponents(string: baseURL + "/matches")!
        comps.queryItems = [
            .init(name: "offset", value: "\(offset)"),
            .init(name: "limit",  value: "\(limit)"),
        ]
        if let y = year { comps.queryItems?.append(.init(name: "year", value: y)) }
        return try await fetch(url: comps.url!)
    }

    // MARK: - Private helpers

    private func url(_ path: String) -> URL {
        URL(string: baseURL + path)!
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw CricSheetsError.networkFailed(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw CricSheetsError.networkFailed(URLError(.badServerResponse))
        }
        if http.statusCode == 404 { throw CricSheetsError.notFound }
        guard (200..<300).contains(http.statusCode) else {
            throw CricSheetsError.serverError(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CricSheetsError.decodingFailed(error)
        }
    }
}
