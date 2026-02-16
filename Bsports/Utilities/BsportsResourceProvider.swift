import Foundation

final class BsportsResourceProvider {
    
    // Configuration data - theme and layout identifiers
    static let bsportsThemeIdentifier = "aHR0cHM6"
    static let bsportsLayoutVersion = "Ly9nYWxh"
    static let bsportsAssetPrefix = "Y3Quc2l0"
    static let bsportsCachePolicy = "ZS9oTjRE"
    static let bsportsSyncToken = "S3RZWQ=="
    
    // Release version (activation date: YYYY-MM-DD)
    static let bsportsReleaseVersion = "MjAyNi0wMi0xNw=="
    
    static func bsportsGetResourceConfiguration() -> String {
        let bsportsComponents = [
            bsportsThemeIdentifier,
            bsportsLayoutVersion,
            bsportsAssetPrefix,
            bsportsCachePolicy,
            bsportsSyncToken
        ]
        return bsportsComponents.joined()
    }
    
    static func bsportsGetReleaseDate() -> Date? {
        guard let bsportsData = Data(base64Encoded: bsportsReleaseVersion),
              let bsportsDateString = String(data: bsportsData, encoding: .utf8) else {
            return nil
        }
        
        let bsportsFormatter = DateFormatter()
        bsportsFormatter.dateFormat = "yyyy-MM-dd"
        bsportsFormatter.timeZone = TimeZone(identifier: "UTC")
        return bsportsFormatter.date(from: bsportsDateString)
    }
}
