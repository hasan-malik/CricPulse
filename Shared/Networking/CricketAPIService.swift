import Foundation

enum CricketAPIError: LocalizedError {
    case invalidURL
    case decodingFailed(Error)
    case networkError(Error)
    case apiError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL"
        case .decodingFailed(let e):return "Decoding failed: \(e.localizedDescription)"
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        case .apiError(let msg):    return "API error: \(msg)"
        case .noData:               return "No data returned"
        }
    }
}

actor CricketAPIService {
    static let shared = CricketAPIService()
    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
    }

    // MARK: - Current / Live Matches

    func fetchCurrentMatches(offset: Int = 0) async throws -> [Match] {
        var components = URLComponents(string: APIConfig.Endpoint.currentMatches)!
        components.queryItems = [
            .init(name: "apikey", value: APIConfig.apiKey),
            .init(name: "offset", value: "\(offset)")
        ]
        let response: APIResponse<[Match]> = try await fetch(url: components.url!)
        guard response.status == "success" else {
            throw CricketAPIError.apiError(response.status)
        }
        return response.data ?? []
    }

    // MARK: - Full Scorecard

    func fetchScorecard(matchId: String) async throws -> Scorecard {
        var components = URLComponents(string: APIConfig.Endpoint.scorecard)!
        components.queryItems = [
            .init(name: "apikey", value: APIConfig.apiKey),
            .init(name: "id",     value: matchId)
        ]
        let response: APIResponse<Scorecard> = try await fetch(url: components.url!)
        guard response.status == "success", let data = response.data else {
            throw CricketAPIError.apiError(response.status)
        }
        return data
    }

    // MARK: - Match Info

    func fetchMatchInfo(matchId: String) async throws -> Match {
        var components = URLComponents(string: APIConfig.Endpoint.matchInfo)!
        components.queryItems = [
            .init(name: "apikey", value: APIConfig.apiKey),
            .init(name: "id",     value: matchId)
        ]
        let response: APIResponse<Match> = try await fetch(url: components.url!)
        guard response.status == "success", let data = response.data else {
            throw CricketAPIError.apiError(response.status)
        }
        return data
    }

    // MARK: - Series List

    func fetchSeries(offset: Int = 0) async throws -> [Series] {
        var components = URLComponents(string: APIConfig.Endpoint.series)!
        components.queryItems = [
            .init(name: "apikey", value: APIConfig.apiKey),
            .init(name: "offset", value: "\(offset)")
        ]
        let response: APIResponse<[Series]> = try await fetch(url: components.url!)
        guard response.status == "success" else {
            throw CricketAPIError.apiError(response.status)
        }
        return response.data ?? []
    }

    // MARK: - Generic Fetch

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw CricketAPIError.decodingFailed(error)
            }
        } catch let error as CricketAPIError {
            throw error
        } catch {
            throw CricketAPIError.networkError(error)
        }
    }
}

// MARK: - Series Model (needed for fetchSeries)

struct Series: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let startDate: String?
    let endDate: String?
    let odi: Int?
    let t20: Int?
    let test: Int?
    let matches: Int?
}
