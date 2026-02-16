import Foundation
import os.log

@MainActor
class BsportsScorersService {
    static let shared = BsportsScorersService()
    
    private let apiClient = BsportsAPIClient.shared
    private var cache: [String: ([Scorer], Date)] = [:]
    private let cacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours
    private let logger = Logger(subsystem: "com.bsports", category: "ScorersService")
    
    private init() {}
    
    func fetchScorers(competitionId: String, season: Int? = nil, limit: Int = 10) async throws -> [Scorer] {
        var endpoint = "competitions/\(competitionId)/scorers?limit=\(limit)"
        if let season = season {
            endpoint += "&season=\(season)"
        }
        
        let cacheKey = endpoint
        
        if let (cached, timestamp) = cache[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheTTL {
            logger.info("💾 [ScorersService] Cache HIT")
            return cached
        }
        
        let response: FootballDataOrgScorersResponse = try await apiClient.fetchFootballDataOrg(
            endpoint: endpoint,
            responseType: FootballDataOrgScorersResponse.self
        )
        
        let scorers = response.scorers.enumerated().map { index, dto in
            Scorer(
                id: "\(dto.player.id)-\(dto.team.id)",
                playerId: dto.player.id,
                playerName: dto.player.name,
                teamId: String(dto.team.id),
                teamName: dto.team.name,
                teamLogoURL: dto.team.crest,
                goals: dto.goals ?? 0,
                playedMatches: dto.playedMatches,
                position: dto.player.position
            )
        }
        
        cache[cacheKey] = (scorers, Date())
        logger.info("✅ [ScorersService] Fetched \(scorers.count) scorers")
        return scorers
    }
}
