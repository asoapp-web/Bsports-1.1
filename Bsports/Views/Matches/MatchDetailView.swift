import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @StateObject private var favoritesStore = BsportsFavoritesStore.shared
    @StateObject private var watchedStore = BsportsWatchedStore.shared
    @State private var showWatchedConfirmation = false
    @State private var head2HeadMatches: [Match] = []
    @State private var h2hLoading = false
    
    var body: some View {
        ZStack {
            Color.fanBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Match Card
                    VStack(spacing: 20) {
                        // League Badge
                        Text(match.leagueName)
                            .font(.montserrat(.medium, size: 14))
                            .foregroundColor(.fanPrimaryBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.fanPrimaryBlue.opacity(0.1))
                            .cornerRadius(20)
                        
                        // Teams and Score
                        HStack(spacing: 16) {
                            // Home Team
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: match.homeTeamLogoURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Image(systemName: "sportscourt.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.fanGrayText)
                                }
                                .frame(width: 70, height: 70)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                
                                Text(match.homeTeamName)
                                    .font(.montserrat(.semibold, size: 15))
                                    .foregroundColor(.fanTextPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Score
                            VStack(spacing: 8) {
                                if let homeScore = match.homeScore, let awayScore = match.awayScore {
                                    Text("\(homeScore) - \(awayScore)")
                                        .font(.montserrat(.bold, size: 32))
                                        .foregroundColor(.fanTextPrimary)
                                } else {
                                    Text("VS")
                                        .font(.montserrat(.bold, size: 24))
                                        .foregroundColor(.fanGrayText)
                                }
                                
                                StatusBadge(status: match.status)
                            }
                            
                            // Away Team
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: match.awayTeamLogoURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Image(systemName: "sportscourt.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.fanGrayText)
                                }
                                .frame(width: 70, height: 70)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                
                                Text(match.awayTeamName)
                                    .font(.montserrat(.semibold, size: 15))
                                    .foregroundColor(.fanTextPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Date and Time
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.fanPrimaryBlue)
                            Text(BsportsDateFormatter.shared.formatFullDate(match.date))
                                .font(.montserratBody)
                                .foregroundColor(.fanGrayText)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.fanBackgroundCard, Color.fanPrimaryBlue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .fanPrimaryBlue.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    // Mark as Watched Button
                    if match.status == .finished {
                        if watchedStore.isWatched(matchId: match.id) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.fanSuccess)
                                Text("Watched")
                                    .foregroundColor(.fanSuccess)
                            }
                            .font(.montserrat(.semibold, size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.fanSuccess.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                markAsWatched()
                            }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Mark as Watched")
                                }
                                .font(.montserrat(.semibold, size: 16))
                                .foregroundColor(.fanTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.fanPrimaryBlue)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Head-to-Head Section
                    Head2HeadSection(
                        match: match,
                        h2hMatches: $head2HeadMatches,
                        isLoading: $h2hLoading
                    )
                    
                    // Venue (if available)
                    if let venueName = match.venueName {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Venue")
                                .font(.montserrat(.semibold, size: 18))
                                .foregroundColor(.fanTextPrimary)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.fanPrimaryBlue)
                                
                                Text(venueName)
                                    .font(.montserratBody)
                                    .foregroundColor(.fanTextPrimary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.fanBackgroundCard, Color.fanPrimaryBlue.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(match.leagueName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func markAsWatched() {
        watchedStore.addWatchedMatch(WatchedMatchRecord(
            matchId: match.id,
            homeTeamName: match.homeTeamName,
            awayTeamName: match.awayTeamName,
            homeScore: match.homeScore,
            awayScore: match.awayScore,
            leagueName: match.leagueName
        ))
        BsportsHapticManager.shared.success()
    }
}

struct Head2HeadSection: View {
    let match: Match
    @Binding var h2hMatches: [Match]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Head-to-Head")
                .font(.montserrat(.semibold, size: 18))
                .foregroundColor(.fanTextPrimary)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.fanPrimaryBlue)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if h2hMatches.isEmpty {
                Text("No previous encounters")
                    .font(.montserratBody)
                    .foregroundColor(.fanGrayText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(h2hMatches.prefix(5)) { h2hMatch in
                        NavigationLink(destination: MatchDetailView(match: h2hMatch)) {
                            H2HMatchRow(match: h2hMatch, homeTeamId: match.homeTeamId)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.fanBackgroundCard, Color.fanPrimaryBlue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .task {
            await loadH2H()
        }
    }
    
    private func loadH2H() async {
        isLoading = true
        do {
            h2hMatches = try await BsportsFixturesService.shared.fetchHead2Head(matchId: match.id, limit: 5)
        } catch {
            h2hMatches = []
        }
        isLoading = false
    }
}

struct H2HMatchRow: View {
    let match: Match
    let homeTeamId: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(match.homeTeamName)
                .font(.montserrat(.medium, size: 13))
                .foregroundColor(.fanTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if let h = match.homeScore, let a = match.awayScore {
                Text("\(h) - \(a)")
                    .font(.montserrat(.bold, size: 14))
                    .foregroundColor(.fanPrimaryBlue)
                    .frame(width: 50, alignment: .center)
            } else {
                Text("vs")
                    .font(.montserrat(.medium, size: 12))
                    .foregroundColor(.fanGrayText)
                    .frame(width: 50, alignment: .center)
            }
            
            Text(match.awayTeamName)
                .font(.montserrat(.medium, size: 13))
                .foregroundColor(.fanTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.fanBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(match: Match(
            id: "1",
            leagueId: "2021",
            leagueName: "Premier League",
            season: 2024,
            homeTeamId: "57",
            awayTeamId: "65",
            homeTeamName: "Arsenal",
            awayTeamName: "Manchester City",
            date: Date(),
            status: .finished,
            homeScore: 2,
            awayScore: 1
        ))
    }
}
