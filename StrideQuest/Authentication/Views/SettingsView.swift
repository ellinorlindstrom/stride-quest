//
//  SettingsView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-10.
//

import SwiftUI

// MARK: - Profile Section
struct ProfileSection: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var showImagePicker: Bool
    @Binding var newName: String
    
    var body: some View {
            Section {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showImagePicker = true
                        } label: {  // Use proper button syntax
                            ProfileImageView(profileImage: authManager.profileImage)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    TextField("Your Name", text: $newName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    Button("Update Profile") {
                        if !newName.isEmpty {
                            authManager.updateUserName(newName)
                        }
                    }
                    .foregroundColor(.blue)
                }
            } header: {
                Text("Profile")
            }
        }
    }
// MARK: - Profile Image View
struct ProfileImageView: View {
    let profileImage: UIImage?
    
    var body: some View {
        if let profileImage = profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
        } else {
            ZStack {
                Circle()
                    .fill(Color(red: 0.075, green: 0.278, blue: 0.396))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Account Information Section
struct AccountInformationSection: View {
    let email: String?
    let userId: String?
    
    var body: some View {
        Section {
            if let email = email {
                Text(email)
                    .foregroundColor(.secondary)
            }
            
            if let userId = userId {
                Text("User ID: \(userId)")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        } header: {
            Text("Account Information")
        }
    }
}

// MARK: - Actions Section
struct ActionsSection: View {
    @Binding var showSignOutAlert: Bool
    @Binding var showResetAlert: Bool
    
    var body: some View {
        Section {
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
            }
            
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
            }
        }
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var newName: String = ""
    @State private var showImagePicker = false
    @State private var showSignOutAlert = false
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                ProfileSection(
                    authManager: authManager,
                    showImagePicker: $showImagePicker,
                    newName: $newName
                )
                
                AccountInformationSection(
                    email: authManager.userEmail,
                    userId: authManager.userID
                )
                
                ActionsSection(
                    showSignOutAlert: $showSignOutAlert,
                    showResetAlert: $showResetAlert
                )
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newName = authManager.userName ?? ""
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: Binding(
                get: { authManager.profileImage },
                set: { newImage in
                    if let image = newImage {
                        authManager.saveProfileImage(image)
                    }
                }
            ))
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Reset Data", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Add reset data functionality here
                dismiss()
            }
        } message: {
            Text("This will reset all your data. This action cannot be undone.")
        }
    }
}
