//
//  LoginView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authManager: AuthenticationManager
    
    var body: some View {
        
        VStack(spacing: 20) {
            Spacer(minLength: 50)
            Text("Welcome to Stride Quest")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Sign in to track your progress")
                .foregroundStyle(.secondary)
            
            SignInWithAppleButton(.signIn) { request in
                          request.requestedScopes = [.fullName, .email]
                      } onCompletion: { result in
                          authManager.handleSignInWithAppleCompletion(result)
                      }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 44)
                .padding(.horizontal)
            
            Spacer(minLength: 50)
        }
        .padding(.vertical, 40)
        .frame(maxHeight: .infinity)
    }
}
