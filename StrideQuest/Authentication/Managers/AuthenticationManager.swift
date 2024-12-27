import Foundation
import SwiftUI
import AuthenticationServices
import UserNotifications

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var userID: String?
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var profileImage: UIImage?
    @Published var activeNotification: ActiveNotification?

    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        switch result {
        case .success(let auth):
            switch auth.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                let userIdentifier = appleIDCredential.user
                print("Got user identifier: \(userIdentifier)")
                self.userID = userIdentifier
                
                // Handle name
                if let givenName = appleIDCredential.fullName?.givenName,
                   let familyName = appleIDCredential.fullName?.familyName {
                    let fullName = "\(givenName) \(familyName)"
                    self.userName = fullName
                    UserDefaults.standard.set(fullName, forKey: "userName")
                    print("Saved new name to UserDefaults: \(fullName)")
                } else {
                    // If we don't get a new name, try to get existing name from UserDefaults
                    if let existingName = UserDefaults.standard.string(forKey: "userName") {
                        self.userName = existingName
                        print("Using existing name from UserDefaults: \(existingName)")
                    } else {
                        // If no name is available, use the first part of the user identifier or a default name
                        let defaultName = "User \(userIdentifier.prefix(4))"
                        self.userName = defaultName
                        UserDefaults.standard.set(defaultName, forKey: "userName")
                        print("Using default name: \(defaultName)")
                    }
                }
                
                UserDefaults.standard.set(userIdentifier, forKey: "userIdentifier")
                
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
                
            default:
                break
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        profileImage = image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "userProfileImage")
            
            // Preserve the existing username
            if let currentName = self.userName {
                UserDefaults.standard.set(currentName, forKey: "userName")
            }
            
            // Make sure we're not accidentally triggering any authentication checks
            // that might reset the username
            if !isAuthenticated {
                self.isAuthenticated = true
            }
        }
    }
    
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "userProfileImage"),
           let image = UIImage(data: imageData) {
            profileImage = image
        }
    }
    
    func updateUserName(_ newName: String) {
        DispatchQueue.main.async {
            self.userName = newName
            UserDefaults.standard.set(newName, forKey: "userName")
        }
    }
    
    func checkAuthentication() {
        if let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier") {
            self.userID = userIdentifier
            if let savedName = UserDefaults.standard.string(forKey: "userName") {
                self.userName = savedName
                print("Restored name from UserDefaults: \(savedName)")
            } else {
                let defaultName = "User \(userIdentifier.prefix(4))"
                self.userName = defaultName
                UserDefaults.standard.set(defaultName, forKey: "userName")
                print("Set default name during restoration: \(defaultName)")
            }
            self.isAuthenticated = true
            loadProfileImage()
            print("Authentication restored - ID: \(userIdentifier), Name: \(self.userName ?? "nil")")
        }
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }
    
    struct ActiveNotification: Equatable {
            let type: String
            let id: String
        }
    
    func handleMilestoneNotification(milestoneId: String) {
            DispatchQueue.main.async {
                self.activeNotification = ActiveNotification(
                    type: "milestone",
                    id: milestoneId
                )
            }
        }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "userIdentifier")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userProfileImage")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userID = nil
            self.userName = nil
            self.userEmail = nil
            self.profileImage = nil
        }
    }
}

