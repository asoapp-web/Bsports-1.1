import SwiftUI

struct SettingsView: View {
    @AppStorage(BsportsUserDefaultsKeys.hapticFeedbackEnabled) private var hapticFeedbackEnabled = true
    @StateObject private var bsportsPhotoManager = BsportsProfilePhotoManager.shared
    @State private var bsportsShowCameraPicker = false
    @State private var bsportsShowLibraryPicker = false
    @State private var bsportsShowSourceActionSheet = false
    @State private var bsportsShowPermissionAlert = false
    @State private var bsportsPermissionMessage = ""
    
    var body: some View {
        ZStack {
            Color.fanBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    SettingsSection(title: "Profile Photo") {
                        HStack(spacing: 16) {
                            if let bsportsPhoto = bsportsPhotoManager.bsportsProfilePhoto {
                                Image(uiImage: bsportsPhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.fanGrayText)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    bsportsShowSourceActionSheet = true
                                } label: {
                                    Text("Choose Photo")
                                        .font(.montserrat(.medium, size: 14))
                                        .foregroundColor(.fanPrimaryBlue)
                                }
                                
                                if bsportsPhotoManager.bsportsProfilePhoto != nil {
                                    Button {
                                        bsportsPhotoManager.bsportsDeletePhoto()
                                    } label: {
                                        Text("Remove Photo")
                                            .font(.montserrat(.medium, size: 14))
                                            .foregroundColor(.fanError)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Preferences Section
                    SettingsSection(title: "Preferences") {
                        SettingsToggle(
                            icon: "hand.tap.fill",
                            iconColor: .fanPrimaryBlue,
                            title: "Haptic Feedback",
                            isOn: $hapticFeedbackEnabled
                        )
                    }
                    
                    // Data Section
                    SettingsSection(title: "Data") {
                        SettingsRow(
                            icon: "arrow.clockwise",
                            iconColor: .fanSuccess,
                            title: "Refresh Data",
                            showChevron: true
                        )
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .fanError,
                            title: "Clear Cache",
                            showChevron: true
                        )
                    }
                    
                    // About Section
                    VStack(spacing: 16) {
                        Image("BsportsLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .shadow(color: .fanPrimaryBlue.opacity(0.3), radius: 15, x: 0, y: 5)
                        
                        Text("Bsports")
                            .font(.montserrat(.bold, size: 24))
                            .foregroundColor(.fanTextPrimary)
                        
                        Text("Your ultimate football companion")
                            .font(.montserratCaption)
                            .foregroundColor(.fanGrayText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Choose Photo Source", isPresented: $bsportsShowSourceActionSheet) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    BsportsPhotoPermissionHelper.bsportsRequestCameraAccess { granted in
                        if granted {
                            bsportsShowCameraPicker = true
                        } else {
                            bsportsPermissionMessage = "Camera access is required to capture your profile photo."
                            bsportsShowPermissionAlert = true
                        }
                    }
                }
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Button("Photo Library") {
                    BsportsPhotoPermissionHelper.bsportsRequestPhotoLibraryAccess { granted in
                        if granted {
                            bsportsShowLibraryPicker = true
                        } else {
                            bsportsPermissionMessage = "Photo library access is required to select your profile photo."
                            bsportsShowPermissionAlert = true
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select a source for your profile photo")
        }
        .fullScreenCover(isPresented: $bsportsShowCameraPicker) {
            BsportsImagePicker(bsportsSourceType: .camera) { image in
                bsportsPhotoManager.bsportsSavePhoto(image)
            }
        }
        .fullScreenCover(isPresented: $bsportsShowLibraryPicker) {
            BsportsImagePicker(bsportsSourceType: .photoLibrary) { image in
                bsportsPhotoManager.bsportsSavePhoto(image)
            }
        }
        .alert("Permission Required", isPresented: $bsportsShowPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bsportsPermissionMessage)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.montserrat(.semibold, size: 14))
                .foregroundColor(.fanGrayText)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                LinearGradient(
                    colors: [Color.fanBackgroundCard, Color.fanPrimaryBlue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .fanPrimaryBlue.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            Text(title)
                .font(.montserratBody)
                .foregroundColor(.fanTextPrimary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.montserratBody)
                    .foregroundColor(.fanGrayText)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.fanGrayText)
            }
        }
        .padding()
    }
}

struct SettingsToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            Text(title)
                .font(.montserratBody)
                .foregroundColor(.fanTextPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.fanPrimaryBlue)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
