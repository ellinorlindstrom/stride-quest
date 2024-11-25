import Foundation
import SwiftUI
import AuthenticationServices

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var userName: String?
    @Published var userEmail: String?
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            switch auth.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                let userIdentifier = appleIDCredential.user
                self.userID = userIdentifier
                
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                if let givenName = fullName?.givenName,
                   let familyName = fullName?.familyName {
                    self.userName = "\(givenName) \(familyName)"
                }
                
                if let email = email {
                    self.userEmail = email
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
    
    func signOut() {
        
        UserDefaults.standard.removeObject(forKey: "userIdentifier")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userID = nil
            self.userName = nil
            self.userEmail = nil
        }
    }
    
    func checkAuthentication() {
        if let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier") {
            self.userID = userIdentifier
            self.isAuthenticated = true
        }
    }
}


