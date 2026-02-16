import Foundation

struct Scorer: Identifiable, Codable, Equatable {
    let id: String
    let playerId: Int
    let playerName: String
    let teamId: String
    let teamName: String
    let teamLogoURL: String?
    let goals: Int
    let playedMatches: Int?
    let position: String?
}
