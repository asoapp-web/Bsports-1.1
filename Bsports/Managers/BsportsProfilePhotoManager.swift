import SwiftUI
import UIKit
import Combine

final class BsportsProfilePhotoManager: ObservableObject {
    
    static let shared = BsportsProfilePhotoManager()
    
    @Published var bsportsProfilePhoto: UIImage?
    
    private let bsportsStorageKey = "bsports_profile_photo_v1"
    
    private init() {
        bsportsLoadPhoto()
    }
    
    func bsportsSavePhoto(_ image: UIImage) {
        guard let bsportsData = image.jpegData(compressionQuality: 0.8) else { return }
        UserDefaults.standard.set(bsportsData, forKey: bsportsStorageKey)
        bsportsProfilePhoto = image
    }
    
    func bsportsLoadPhoto() {
        guard let bsportsData = UserDefaults.standard.data(forKey: bsportsStorageKey),
              let bsportsImage = UIImage(data: bsportsData) else {
            bsportsProfilePhoto = nil
            return
        }
        bsportsProfilePhoto = bsportsImage
    }
    
    func bsportsDeletePhoto() {
        UserDefaults.standard.removeObject(forKey: bsportsStorageKey)
        bsportsProfilePhoto = nil
    }
}
