import SwiftUI

struct BsportsRootView: View {
    @ObservedObject private var bsportsFlow = BsportsFlowController.shared
    
    var body: some View {
        ZStack {
            Group {
                switch bsportsFlow.bsportsDisplayMode {
                case .preparing, .original:
                    SplashView()
                case .webContent:
                    BsportsDisplayView()
                }
            }
            .opacity(bsportsFlow.bsportsIsLoading ? 0 : 1)
            
            if bsportsFlow.bsportsIsLoading {
                BsportsLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: bsportsFlow.bsportsIsLoading)
    }
}

#Preview {
    BsportsRootView()
}
