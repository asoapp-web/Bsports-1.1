import SwiftUI
import UIKit
import AVFoundation
import Photos

struct BsportsImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let bsportsSourceType: UIImagePickerController.SourceType
    let bsportsOnImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let bsportsPicker = UIImagePickerController()
        bsportsPicker.sourceType = bsportsSourceType
        bsportsPicker.allowsEditing = true
        bsportsPicker.delegate = context.coordinator
        return bsportsPicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> BsportsImagePickerCoordinator {
        BsportsImagePickerCoordinator(bsportsOnImagePicked: bsportsOnImagePicked, bsportsOnCancel: { dismiss() })
    }
}

final class BsportsImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let bsportsOnImagePicked: (UIImage) -> Void
    let bsportsOnCancel: () -> Void
    
    init(bsportsOnImagePicked: @escaping (UIImage) -> Void, bsportsOnCancel: @escaping () -> Void) {
        self.bsportsOnImagePicked = bsportsOnImagePicked
        self.bsportsOnCancel = bsportsOnCancel
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let bsportsImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            bsportsOnImagePicked(bsportsImage)
        }
        bsportsOnCancel()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        bsportsOnCancel()
    }
}

// MARK: - Permission Helpers

enum BsportsPhotoPermissionHelper {
    
    static func bsportsRequestCameraAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }
    
    static func bsportsRequestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        let bsportsStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch bsportsStatus {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        default:
            completion(false)
        }
    }
}
