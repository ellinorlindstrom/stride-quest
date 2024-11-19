//
//  LoginView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to Stride Quest")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Sign in to track your progress")
                .foregroundStyle(.secondary)
            
            SignInWithAppleButton(authManager: authManager)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            authManager.checkAuthentication()
        }
    }
}
