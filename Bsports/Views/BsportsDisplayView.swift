import SwiftUI
import WebKit

struct BsportsDisplayView: View {
    @ObservedObject private var bsportsFlow = BsportsFlowController.shared
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let bsportsEndpoint = bsportsFlow.bsportsTargetEndpoint {
                BsportsWebView(bsportsResourcePath: bsportsEndpoint)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - WebView Wrapper

struct BsportsWebView: UIViewRepresentable {
    let bsportsResourcePath: String
    
    private static let bsportsUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    private static let bsportsCookiesKey = "bsports_saved_cookies_v1"
    
    func makeCoordinator() -> BsportsCoordinator {
        BsportsCoordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let bsportsConfig = WKWebViewConfiguration()
        bsportsConfig.allowsInlineMediaPlayback = true
        bsportsConfig.mediaTypesRequiringUserActionForPlayback = []
        bsportsConfig.allowsAirPlayForMediaPlayback = true
        bsportsConfig.allowsPictureInPictureMediaPlayback = true
        bsportsConfig.websiteDataStore = .default()
        
        let bsportsWebView = WKWebView(frame: .zero, configuration: bsportsConfig)
        bsportsWebView.customUserAgent = Self.bsportsUserAgent
        bsportsWebView.allowsBackForwardNavigationGestures = true
        bsportsWebView.allowsLinkPreview = false
        bsportsWebView.scrollView.keyboardDismissMode = .interactive
        bsportsWebView.isOpaque = false
        bsportsWebView.backgroundColor = .black
        
        let bsportsRefresh = UIRefreshControl()
        bsportsRefresh.addTarget(context.coordinator, action: #selector(BsportsCoordinator.bsportsHandleRefresh), for: .valueChanged)
        bsportsWebView.scrollView.refreshControl = bsportsRefresh
        
        bsportsWebView.navigationDelegate = context.coordinator
        bsportsWebView.uiDelegate = context.coordinator
        context.coordinator.bsportsWebViewRef = bsportsWebView
        
        bsportsLoadCookies(into: bsportsWebView) {
            if let bsportsURL = URL(string: bsportsResourcePath) {
                bsportsWebView.load(URLRequest(url: bsportsURL))
            }
        }
        
        return bsportsWebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func bsportsLoadCookies(into webView: WKWebView, completion: @escaping () -> Void) {
        guard let bsportsData = UserDefaults.standard.data(forKey: Self.bsportsCookiesKey),
              let bsportsArray = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(bsportsData) as? [[String: Any]] else {
            completion()
            return
        }
        
        let bsportsGroup = DispatchGroup()
        for bsportsCookieDict in bsportsArray {
            
            var bsportsConverted: [HTTPCookiePropertyKey: Any] = [:]
            for (bsportsKey, bsportsValue) in bsportsCookieDict {
                bsportsConverted[HTTPCookiePropertyKey(bsportsKey)] = bsportsValue
            }
            
            if let bsportsCookie = HTTPCookie(properties: bsportsConverted) {
                bsportsGroup.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(bsportsCookie) {
                    bsportsGroup.leave()
                }
            }
        }
        bsportsGroup.notify(queue: .main, execute: completion)
    }
    
    static func bsportsSaveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { bsportsCookies in
            let bsportsProps = bsportsCookies.compactMap { bsportsCookie -> [String: Any]? in
                guard let bsportsDict = bsportsCookie.properties else { return nil }
                var bsportsResult: [String: Any] = [:]
                for (bsportsKey, bsportsValue) in bsportsDict {
                    bsportsResult[bsportsKey.rawValue] = bsportsValue
                }
                return bsportsResult
            }
            
            guard !bsportsProps.isEmpty else { return }
            
            if let bsportsData = try? NSKeyedArchiver.archivedData(withRootObject: bsportsProps, requiringSecureCoding: false) {
                UserDefaults.standard.set(bsportsData, forKey: bsportsCookiesKey)
            }
        }
    }
}

// MARK: - Coordinator

final class BsportsCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var bsportsWebViewRef: WKWebView?
    
    @objc func bsportsHandleRefresh() {
        bsportsWebViewRef?.reload()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        bsportsWebViewRef = webView
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
        BsportsWebView.bsportsSaveCookies(from: webView)
        
        if let bsportsFinalPath = webView.url?.absoluteString {
            BsportsFlowController.shared.bsportsCacheResource(bsportsFinalPath)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        print("📱 [Bsports] Content load interrupted")
        BsportsFlowController.shared.bsportsActivateSecondaryMode()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("📱 [Bsports] Content unavailable")
        BsportsFlowController.shared.bsportsActivateSecondaryMode()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let bsportsURL = navigationAction.request.url else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        let bsportsScheme = bsportsURL.scheme?.lowercased() ?? ""
        if bsportsScheme != "http" && bsportsScheme != "https" {
            UIApplication.shared.open(bsportsURL)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let bsportsURL = navigationAction.request.url {
            webView.load(URLRequest(url: bsportsURL))
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let bsportsAlert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        bsportsAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        
        if let bsportsVC = webView.window?.rootViewController {
            bsportsVC.present(bsportsAlert, animated: true)
        } else {
            completionHandler()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let bsportsAlert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        bsportsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        bsportsAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        
        if let bsportsVC = webView.window?.rootViewController {
            bsportsVC.present(bsportsAlert, animated: true)
        } else {
            completionHandler(false)
        }
    }
}
