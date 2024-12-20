//
//  SignInWithAppleButton.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct SignInWithAppleButton: View {
    @ObservedObject var authManager: AuthenticationManager
    
    var body: some View {
        SignInWithAppleButtonViewRepresentable(authManager: authManager)
            .frame(height: 50)
            .cornerRadius(10)
            .disabled(authManager.isLoading)
        
        if authManager.isLoading {
                        HStack {
                            Spacer()
                            LoadingView()
                                .frame(width: 20, height: 20)  // Smaller size for button
                            Spacer()
                        }
                    }
    }
}

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let authManager: AuthenticationManager
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator,
                        action: #selector(Coordinator.handleSignInWithAppleTapped),
                        for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButtonViewRepresentable
        
        init(_ parent: SignInWithAppleButtonViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleSignInWithAppleTapped() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            parent.authManager.handleSignInWithAppleRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            return scene?.windows.first ?? UIWindow()
        }
        
        func authorizationController(controller: ASAuthorizationController,
                                   didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.authManager.handleSignInWithAppleCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController,
                                   didCompleteWithError error: Error) {
            parent.authManager.handleSignInWithAppleCompletion(.failure(error))
        }
    }
}

#Preview {
    LoginView(authManager: AuthenticationManager())
}
