import Foundation
import Combine

@MainActor
class LeagueDetailViewModel: ObservableObject {
    var leagueId: String
    var season: Int?
    @Published var standings: [StandingsEntry] = []
    @Published var scorers: [Scorer] = []
    @Published var isLoading = false
    @Published var scorersLoading = false
    @Published var errorMessage: String?
    
    private let standingsService = BsportsStandingsService.shared
    private let scorersService = BsportsScorersService.shared
    
    init(leagueId: String, season: Int? = nil) {
        self.leagueId = leagueId
        self.season = season
    }
    
    func loadStandings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            standings = try await standingsService.fetchStandings(leagueId: leagueId, season: season)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func loadScorers() async {
        scorersLoading = true
        do {
            scorers = try await scorersService.fetchScorers(competitionId: leagueId, season: season, limit: 10)
        } catch {
            scorers = []
        }
        scorersLoading = false
    }
}
