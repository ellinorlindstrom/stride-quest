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
            Text("Stride Quest")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.black)
                .padding(.top, 40)
                .foregroundStyle(Color(red: 0.075, green: 0.278, blue: 0.396))
            
                Text("Transforming everyday movement into adventures!")
                .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.075, green: 0.278, blue: 0.396))

            
            Text("Sign in to track your progress")
                .foregroundStyle(Color(red: 0.467, green: 0.471, blue: 0.471))
                .font(.system(.callout, design: .rounded))
            
            SignInWithAppleButton(authManager: authManager)
                           .frame(height: 44)
                           .padding(.horizontal)
                           .cornerRadius(10)
                           //.signInWithAppleButtonStyle(.white)
            
            Spacer(minLength: 50)
        }
        .padding(.vertical, 40)
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
        .background(Color(red: 0.957, green: 0.949, blue: 0.925))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
