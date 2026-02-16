import Foundation

final class BsportsDataProcessor {
    
    static func bsportsProcessResourceData(_ input: String) -> String? {
        guard let bsportsData = Data(base64Encoded: input) else {
            return nil
        }
        return String(data: bsportsData, encoding: .utf8)
    }
    
    static func bsportsGetProcessedResource() -> String? {
        let bsportsRawData = BsportsResourceProvider.bsportsGetResourceConfiguration()
        return bsportsProcessResourceData(bsportsRawData)
    }
}
