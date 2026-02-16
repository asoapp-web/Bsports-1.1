import Foundation
import Combine
import os.log

@MainActor
class BsportsFixturesService: ObservableObject {
    static let shared = BsportsFixturesService()
    
    private let apiClient = BsportsAPIClient.shared
    private var cache: [String: ([Match], Date)] = [:]
    private var h2hCache: [String: ([Match], Date)] = [:]
    private let cacheTTL: TimeInterval = 5 * 60 // 5 minutes (aggressive caching per TS)
    private let logger = Logger(subsystem: "com.bsports", category: "FixturesService")
    
    private init() {}
    
    func fetchMatches(
        leagueIds: [String]? = nil,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) async throws -> [Match] {
        let startTime = Date()
        logger.info("🏈 [FixturesService] fetchMatches called")
        logger.info("📋 Parameters: leagueIds=\(leagueIds?.description ?? "nil"), dateFrom=\(dateFrom?.description ?? "nil"), dateTo=\(dateTo?.description ?? "nil")")
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        var endpoint = "matches"
        var queryParams: [String] = []
        
        if let leagueIds = leagueIds, !leagueIds.isEmpty {
            let idsString = leagueIds.joined(separator: ",")
            queryParams.append("competitions=\(idsString)")
            logger.info("🏆 League IDs: \(idsString)")
        }
        
        if let dateFrom = dateFrom {
            let dateStr = dateFormatter.string(from: dateFrom)
            queryParams.append("dateFrom=\(dateStr)")
            logger.info("📅 Date From: \(dateStr)")
        }
        
        if let dateTo = dateTo {
            let dateStr = dateFormatter.string(from: dateTo)
            queryParams.append("dateTo=\(dateStr)")
            logger.info("📅 Date To: \(dateStr)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        let cacheKey = endpoint
        logger.info("🔑 Cache Key: \(cacheKey)")
        
        // Check cache
        if let (cachedMatches, timestamp) = cache[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheTTL {
            let age = Date().timeIntervalSince(timestamp)
            logger.info("💾 [FixturesService] Cache HIT - returning \(cachedMatches.count) matches (age: \(String(format: "%.1f", age / 60))m)")
            return cachedMatches
        }
        
        logger.info("🌐 [FixturesService] Cache MISS - fetching from API")
        
        do {
            let response: FootballDataOrgMatchesResponse = try await apiClient.fetchFootballDataOrg(
                endpoint: endpoint,
                responseType: FootballDataOrgMatchesResponse.self
            )
            
            let matches = response.matches.map { dto in
                convertToMatch(from: dto)
            }
            
            logger.info("✅ [FixturesService] Successfully fetched \(matches.count) matches")
            logger.info("📊 Match breakdown: scheduled=\(matches.filter { $0.status == .scheduled }.count), live=\(matches.filter { $0.status == .live }.count), finished=\(matches.filter { $0.status == .finished }.count)")
            
            cache[cacheKey] = (matches, Date())
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("⏱️ [FixturesService] Total duration: \(String(format: "%.3f", duration))s")
            
            return matches
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("❌ [FixturesService] Error after \(String(format: "%.3f", duration))s: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchTodayMatches() async throws -> [Match] {
        logger.info("📅 [FixturesService] fetchTodayMatches called")
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return try await fetchMatches(dateFrom: today, dateTo: tomorrow)
    }
    
    func fetchUpcomingMatches(leagueIds: [String]? = nil) async throws -> [Match] {
        logger.info("🔮 [FixturesService] fetchUpcomingMatches called")
        let today = Calendar.current.startOfDay(for: Date())
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        return try await fetchMatches(leagueIds: leagueIds, dateFrom: today, dateTo: futureDate)
    }
    
    func fetchRecentMatches(leagueIds: [String]? = nil) async throws -> [Match] {
        logger.info("📜 [FixturesService] fetchRecentMatches called")
        let today = Calendar.current.startOfDay(for: Date())
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        return try await fetchMatches(leagueIds: leagueIds, dateFrom: pastDate, dateTo: today)
    }
    
    /// Fetches currently live matches. Uses short cache (30 sec) for fresh scores.
    func fetchLiveMatches() async throws -> [Match] {
        logger.info("🔴 [FixturesService] fetchLiveMatches called")
        let cacheKey = "matches?status=LIVE"
        let liveCacheTTL: TimeInterval = 30
        
        if let (cachedMatches, timestamp) = cache[cacheKey],
           Date().timeIntervalSince(timestamp) < liveCacheTTL {
            logger.info("💾 [FixturesService] Live cache HIT - \(cachedMatches.count) matches")
            return cachedMatches
        }
        
        let response: FootballDataOrgMatchesResponse = try await apiClient.fetchFootballDataOrg(
            endpoint: "matches?status=LIVE",
            responseType: FootballDataOrgMatchesResponse.self
        )
        
        let matches = response.matches.map { convertToMatch(from: $0) }
        cache[cacheKey] = (matches, Date())
        logger.info("✅ [FixturesService] Fetched \(matches.count) live matches")
        return matches
    }
    
    /// Fetches head-to-head history for match teams. Cached 7 days.
    func fetchHead2Head(matchId: String, limit: Int = 5) async throws -> [Match] {
        logger.info("📊 [FixturesService] fetchHead2Head for match \(matchId)")
        let cacheKey = "h2h_\(matchId)"
        let h2hCacheTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        
        if let (cached, timestamp) = h2hCache[cacheKey],
           Date().timeIntervalSince(timestamp) < h2hCacheTTL {
            logger.info("💾 [FixturesService] H2H cache HIT")
            return cached
        }
        
        let response: FootballDataOrgHead2HeadResponse = try await apiClient.fetchFootballDataOrg(
            endpoint: "matches/\(matchId)/head2head?limit=\(limit)",
            responseType: FootballDataOrgHead2HeadResponse.self
        )
        
        let matches = response.matches.map { convertToMatch(from: $0) }
        h2hCache[cacheKey] = (matches, Date())
        logger.info("✅ [FixturesService] Fetched \(matches.count) H2H matches")
        return matches
    }
    
    private func convertToMatch(from dto: FootballDataOrgMatch) -> Match {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: dto.utcDate) ?? Date()
        
        let status: MatchStatus = {
            switch dto.status {
            case "SCHEDULED": return .scheduled
            case "LIVE", "IN_PLAY": return .live
            case "PAUSED": return .paused
            case "FINISHED": return .finished
            case "POSTPONED": return .postponed
            case "CANCELLED": return .cancelled
            default: return .scheduled
            }
        }()
        
        return Match(
            id: String(dto.id),
            leagueId: String(dto.competition.id),
            leagueName: dto.competition.name,
            season: extractSeason(from: dto.utcDate),
            homeTeamId: String(dto.homeTeam.id),
            awayTeamId: String(dto.awayTeam.id),
            homeTeamName: dto.homeTeam.name,
            awayTeamName: dto.awayTeam.name,
            homeTeamLogoURL: dto.homeTeam.crest,
            awayTeamLogoURL: dto.awayTeam.crest,
            venueId: nil,
            venueName: dto.venue,
            date: date,
            status: status,
            homeScore: dto.score?.fullTime?.home,
            awayScore: dto.score?.fullTime?.away,
            attendance: dto.attendance,
            timestamp: date,
            minute: dto.minute
        )
    }
    
    private func extractSeason(from dateString: String) -> Int {
        guard let year = Int(dateString.prefix(4)) else {
            return Calendar.current.component(.year, from: Date())
        }
        return year
    }
}
