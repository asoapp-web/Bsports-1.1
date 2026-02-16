import SwiftUI

struct ScorersView: View {
    @ObservedObject var viewModel: LeagueDetailViewModel
    
    var body: some View {
        Group {
            if viewModel.scorersLoading {
                VStack {
                    Spacer()
                    LottieView.loading()
                        .frame(width: 80, height: 80)
                    Text("Loading scorers...")
                        .font(.montserratCaption)
                        .foregroundColor(.fanGrayText)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.scorers.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.fanGrayText)
                    Text("No scorers available")
                        .font(.montserratHeadline)
                        .foregroundColor(.fanTextPrimary)
                    Text("Top scorers data is not available for this league")
                        .font(.montserratBody)
                        .foregroundColor(.fanGrayText)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.scorers.enumerated()), id: \.element.id) { index, scorer in
                            ScorerRowView(rank: index + 1, scorer: scorer)
                            if index < viewModel.scorers.count - 1 {
                                Divider()
                                    .background(Color.fanGrayText.opacity(0.3))
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(Color.fanBackgroundCard)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding()
                }
            }
        }
        .background(Color.fanBackground)
        .task {
            await viewModel.loadScorers()
        }
    }
}

struct ScorerRowView: View {
    let rank: Int
    let scorer: Scorer
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.montserrat(.bold, size: 16))
                .foregroundColor(rank <= 3 ? .fanPrimaryBlue : .fanGrayText)
                .frame(width: 28, alignment: .center)
            
            AsyncImage(url: URL(string: scorer.teamLogoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.fanGrayText)
            }
            .frame(width: 36, height: 36)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(scorer.playerName)
                    .font(.montserrat(.semibold, size: 15))
                    .foregroundColor(.fanTextPrimary)
                    .lineLimit(1)
                
                Text(scorer.teamName)
                    .font(.montserratCaption)
                    .foregroundColor(.fanGrayText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(scorer.goals)")
                .font(.montserrat(.bold, size: 20))
                .foregroundColor(.fanPrimaryBlue)
                .frame(width: 36, alignment: .trailing)
        }
        .padding()
    }
}

#Preview {
    ScorersView(viewModel: LeagueDetailViewModel(leagueId: "2021", season: 2024))
}
