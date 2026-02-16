import SwiftUI

struct BsportsLoadingView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.fanBackground, Color.fanPrimaryBlue.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("BsportsLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: .fanPrimaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("Bsports")
                    .font(.montserrat(.bold, size: 28))
                    .foregroundColor(.fanTextPrimary)
                    .opacity(logoOpacity)
                
                LottieView.loading()
                    .frame(width: 60, height: 60)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}
