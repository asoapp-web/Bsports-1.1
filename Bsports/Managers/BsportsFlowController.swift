import Foundation
import UIKit
import StoreKit
import Combine

enum BsportsDisplayState {
    case preparing
    case original
    case webContent
}

final class BsportsFlowController: ObservableObject {
    
    static let shared = BsportsFlowController()
    
    @Published var bsportsDisplayMode: BsportsDisplayState = .preparing
    @Published var bsportsTargetEndpoint: String?
    @Published var bsportsIsLoading: Bool = true
    
    private let bsportsFallbackStateKey = "bsports_sync_preferences_v1"
    private let bsportsWebViewShownKey = "bsports_onboarding_complete_v1"
    private let bsportsRatingShownKey = "bsports_feedback_prompted_v1"
    private let bsportsCachedResourceKey = "bsports_cached_content_path_v1"
    
    private init() {
        bsportsInitializeFlow()
    }
    
    private func bsportsInitializeFlow() {
        print("📱 [Bsports] Loading user preferences...")
        
        if bsportsIsTabletDevice() {
            print("📱 [Bsports] Tablet layout configured")
            bsportsActivateSecondaryMode()
            return
        }
        
        if bsportsGetFallbackState() {
            print("📱 [Bsports] Using saved display preferences")
            bsportsActivateSecondaryMode()
            return
        }
        
        if !bsportsCheckTemporalCondition() {
            print("📱 [Bsports] Standard mode enabled")
            bsportsActivateSecondaryMode()
            return
        }
        
        if let bsportsCachedPath = bsportsGetCachedResource() {
            print("📱 [Bsports] Checking cached data...")
            bsportsValidateCachedResource(bsportsCachedPath)
            return
        }
        
        bsportsFetchFromRemote()
    }
    
    private func bsportsFetchFromRemote() {
        guard let bsportsRemoteEndpoint = BsportsDataProcessor.bsportsGetProcessedResource() else {
            print("📱 [Bsports] Using offline mode")
            bsportsActivateSecondaryMode()
            return
        }
        
        print("📱 [Bsports] Syncing data...")
        bsportsValidateEndpointBeforeActivation(bsportsRemoteEndpoint)
    }
    
    private func bsportsValidateCachedResource(_ bsportsPath: String) {
        guard let bsportsValidationURL = URL(string: bsportsPath) else {
            print("📱 [Bsports] Refreshing cache...")
            bsportsClearCachedResource()
            bsportsFetchFromRemote()
            return
        }
        
        var bsportsValidationRequest = URLRequest(url: bsportsValidationURL)
        bsportsValidationRequest.timeoutInterval = 10.0
        bsportsValidationRequest.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: bsportsValidationRequest) { [weak self] _, bsportsResponse, bsportsError in
            guard let self = self else { return }
            
            if bsportsError != nil {
                print("📱 [Bsports] Cache expired, refreshing...")
                DispatchQueue.main.async {
                    self.bsportsClearCachedResource()
                    self.bsportsFetchFromRemote()
                }
                return
            }
            
            if let bsportsHttpResponse = bsportsResponse as? HTTPURLResponse {
                print("📱 [Bsports] Cache check complete")
                
                if bsportsHttpResponse.statusCode >= 200 && bsportsHttpResponse.statusCode <= 403 {
                    print("📱 [Bsports] Data loaded from cache")
                    DispatchQueue.main.async {
                        self.bsportsTargetEndpoint = bsportsPath
                        self.bsportsActivatePrimaryMode()
                    }
                } else {
                    print("📱 [Bsports] Cache outdated, updating...")
                    DispatchQueue.main.async {
                        self.bsportsClearCachedResource()
                        self.bsportsFetchFromRemote()
                    }
                }
            } else {
                print("📱 [Bsports] Refreshing data...")
                DispatchQueue.main.async {
                    self.bsportsClearCachedResource()
                    self.bsportsFetchFromRemote()
                }
            }
        }.resume()
    }
    
    private func bsportsValidateEndpointBeforeActivation(_ bsportsUrl: String) {
        guard let bsportsValidationURL = URL(string: bsportsUrl) else {
            print("📱 [Bsports] Using default configuration")
            bsportsActivateSecondaryMode()
            return
        }
        
        var bsportsValidationRequest = URLRequest(url: bsportsValidationURL)
        bsportsValidationRequest.timeoutInterval = 10.0
        bsportsValidationRequest.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: bsportsValidationRequest) { [weak self] _, bsportsResponse, bsportsError in
            guard let self = self else { return }
            
            if bsportsError != nil {
                print("📱 [Bsports] Network unavailable, using offline mode")
                DispatchQueue.main.async {
                    self.bsportsActivateSecondaryMode()
                }
                return
            }
            
            if let bsportsHttpResponse = bsportsResponse as? HTTPURLResponse {
                print("📱 [Bsports] Sync complete")
                
                if bsportsHttpResponse.statusCode >= 200 && bsportsHttpResponse.statusCode <= 403 {
                    print("📱 [Bsports] Enhanced features enabled")
                    DispatchQueue.main.async {
                        self.bsportsTargetEndpoint = bsportsUrl
                        self.bsportsActivatePrimaryMode()
                    }
                } else {
                    print("📱 [Bsports] Standard features enabled")
                    DispatchQueue.main.async {
                        self.bsportsActivateSecondaryMode()
                    }
                }
            } else {
                print("📱 [Bsports] Using default settings")
                DispatchQueue.main.async {
                    self.bsportsActivateSecondaryMode()
                }
            }
        }.resume()
    }
    
    private func bsportsIsTabletDevice() -> Bool {
        let bsportsIsPhysicallyPad = UIDevice.current.model.contains("iPad")
        let bsportsIsInterfacePad = UIDevice.current.userInterfaceIdiom == .pad
        return bsportsIsPhysicallyPad || bsportsIsInterfacePad
    }
    
    private func bsportsCheckTemporalCondition() -> Bool {
        guard let bsportsActivationDate = BsportsResourceProvider.bsportsGetReleaseDate() else {
            return false
        }
        return Date() >= bsportsActivationDate
    }
    
    private func bsportsGetFallbackState() -> Bool {
        return UserDefaults.standard.bool(forKey: bsportsFallbackStateKey)
    }
    
    private func bsportsSetFallbackState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: bsportsFallbackStateKey)
    }
    
    private func bsportsGetCachedResource() -> String? {
        guard let bsportsEncoded = UserDefaults.standard.string(forKey: bsportsCachedResourceKey),
              let bsportsData = Data(base64Encoded: bsportsEncoded),
              let bsportsPath = String(data: bsportsData, encoding: .utf8) else {
            return nil
        }
        print("📱 [Bsports] Cache hit")
        return bsportsPath
    }
    
    func bsportsCacheResource(_ path: String) {
        guard let bsportsData = path.data(using: .utf8) else { return }
        let bsportsEncoded = bsportsData.base64EncodedString()
        UserDefaults.standard.set(bsportsEncoded, forKey: bsportsCachedResourceKey)
        print("📱 [Bsports] Data cached")
    }
    
    private func bsportsClearCachedResource() {
        UserDefaults.standard.removeObject(forKey: bsportsCachedResourceKey)
        print("📱 [Bsports] Cache cleared")
    }
    
    func bsportsActivateSecondaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.bsportsDisplayMode = .original
            self?.bsportsIsLoading = false
            self?.bsportsSetFallbackState(true)
            print("📱 [Bsports] App ready")
        }
    }
    
    func bsportsActivatePrimaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.bsportsDisplayMode = .webContent
            self?.bsportsIsLoading = false
            UserDefaults.standard.set(true, forKey: self?.bsportsWebViewShownKey ?? "")
            print("📱 [Bsports] App ready")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.bsportsShowRatingIfNeeded()
            }
        }
    }
    
    private func bsportsShowRatingIfNeeded() {
        let bsportsAlreadyShown = UserDefaults.standard.bool(forKey: bsportsRatingShownKey)
        guard !bsportsAlreadyShown else { return }
        
        if let bsportsScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: bsportsScene)
            UserDefaults.standard.set(true, forKey: bsportsRatingShownKey)
            print("📱 [Bsports] Feedback requested")
        }
    }
}
