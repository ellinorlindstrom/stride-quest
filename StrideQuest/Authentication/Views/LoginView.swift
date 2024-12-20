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
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer(minLength: 50)
                Text("STRIDE QUEST")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.black)
                    .foregroundStyle(Color(red: 0.075, green: 0.278, blue: 0.396))
                
                Text("Transforming everyday movement into adventures!")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.075, green: 0.278, blue: 0.396))
                
                
                Text("Sign in to track your progress")
                    .foregroundStyle(Color(red: 0.467, green: 0.471, blue: 0.471))
                    .font(.system(.callout, design: .monospaced))
                    .padding(.top, 20)
                
                SignInWithAppleButton(authManager: authManager)
                    .frame(height: 44)
                    .padding(.horizontal)
                    .cornerRadius(8)
                    .disabled(isLoading)
                
                Spacer(minLength: 50)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 40)
            .frame(maxHeight: .infinity)
            .background(Color(red: 0.957, green: 0.949, blue: 0.925))
            
            if authManager.isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    LoadingView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
