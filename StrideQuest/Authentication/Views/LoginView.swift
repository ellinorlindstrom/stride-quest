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
                // Spacer(minLength: 50)
                Text("STRIDE QUEST")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(Color(.secondSecondarySq))
                
                
                VStack(spacing: 10) {
                    Text("Transform movement into")
                        .font(.system(.headline, design: .default))
                        .fontWeight(.medium)
                    Text("World Adventures")
                        .font(.system(.headline, design: .default))
                        .fontWeight(.bold)
                        
                }
                .foregroundStyle(Color(.primarySq))
                .multilineTextAlignment(.center)
                .zIndex(1)
                
                VStack(spacing: 10) {
                    Text("Sign in to track your progress")
                        .foregroundStyle(Color(.textSq))
                        .font(.system(.callout, design: .default))
                        .padding(.top, 20)
                        .zIndex(1)
                    
                    SignInWithAppleButton(authManager: authManager)
                    // .frame(height: 44)
                        .cornerRadius(8)
                        .disabled(isLoading)
                        //.padding(.vertical, 70)
                        .padding(.horizontal, 40)
                        .background(
                            Image("sq-bg-2")
                                .resizable()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(contentMode: .fill)
                                .offset(y: 30)
                                .ignoresSafeArea() // Extends beyond safe area edges
                        )
                }
                .padding(.bottom, 90)
            }
            
            .frame(maxHeight: .infinity)
            .background(Color(.backgroundSq)
            )
            
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
