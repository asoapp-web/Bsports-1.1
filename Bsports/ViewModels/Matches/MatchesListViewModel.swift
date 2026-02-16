import Foundation
import Combine

@MainActor
class MatchesListViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var liveMatches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFilters = false
    
    private let fixturesService = BsportsFixturesService.shared
    private let favoritesStore = BsportsFavoritesStore.shared
    
    @Published var selectedSegment = 0
    
    func loadMatches() async {
        isLoading = true
        errorMessage = nil
        
        let liveTask = Task { try? await fixturesService.fetchLiveMatches() }
        
        do {
            switch selectedSegment {
            case 0:
                matches = try await fixturesService.fetchTodayMatches()
            case 1:
                let ids = favoritesStore.favoriteLeagues().map { $0.id }
                matches = try await fixturesService.fetchUpcomingMatches(leagueIds: ids.isEmpty ? nil : ids)
            case 2:
                let ids = favoritesStore.favoriteLeagues().map { $0.id }
                matches = try await fixturesService.fetchRecentMatches(leagueIds: ids.isEmpty ? nil : ids)
            default:
                matches = try await fixturesService.fetchTodayMatches()
            }
        } catch {
            errorMessage = error.localizedDescription
            matches = []
        }
        
        liveMatches = await liveTask.value ?? []
        isLoading = false
    }
    
    func loadLiveMatches() async {
        do {
            liveMatches = try await fixturesService.fetchLiveMatches()
        } catch {
            // Silently fail for live - don't override existing
        }
    }
    
    func refresh() async {
        await loadMatches()
    }
}
