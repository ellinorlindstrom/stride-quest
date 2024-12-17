import SwiftUI

// MARK: - Profile Section
struct ProfileSection: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var showImagePicker: Bool
    @Binding var newName: String
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section {
            VStack(spacing: 20) {
                // Profile Image with animation and feedback
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            showImagePicker = true
                        }
                    } label: {
                        ProfileImageView(profileImage: authManager.profileImage)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.8), lineWidth: 3)
                                    .scaleEffect(showImagePicker ? 1.1 : 1.0)
                            )
                            .overlay(
                                Image(systemName: "camera.circle.fill")
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 35, y: 35)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                
                // Name editing with animation
                HStack(alignment: .center, spacing: 8) {
                    Spacer()
                    
                    if isEditingName {
                        HStack {
                            TextField("Your Name", text: $tempName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .transition(.move(edge: .top))
                                .submitLabel(.done)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 200)
                                .onSubmit {
                                    saveNameChanges()
                                }
                            
                            Button {
                                saveNameChanges()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }
                            
                            Button {
                                cancelNameEdit()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 20))
                            }
                        }
                    } else {
                        Text(newName.isEmpty ? "Add your name" : newName)
                            .foregroundColor(newName.isEmpty ? .secondary : .primary)
                        
                        Button {
                            startNameEdit()
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 10)
        } header: {
            Text("Profile")
                .textCase(.uppercase)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func startNameEdit() {
        tempName = newName
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingName = true
        }
    }
    
    private func saveNameChanges() {
        if !tempName.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                newName = tempName
                authManager.updateUserName(tempName)
                isEditingName = false
            }
        }
    }
    
    private func cancelNameEdit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            tempName = newName
            isEditingName = false
        }
    }
    
    private func updateNameIfNeeded() {
        if !newName.isEmpty {
            authManager.updateUserName(newName)
        }
        isEditingName = false
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profileImage: UIImage?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            } else {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ?
                              Color(red: 0.2, green: 0.4, blue: 0.6) :
                                Color(red: 0.075, green: 0.278, blue: 0.396))
                        .frame(width: 120, height: 120)
                        .shadow(radius: 5)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
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
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text(email)
                        .textSelection(.enabled)
                }
            }
            
            if let userId = userId {
                HStack {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundColor(.blue)
                    Text(userId)
                        .textSelection(.enabled)
                        .font(.footnote)
                }
            }
        } header: {
            Text("Account Information")
                .textCase(.uppercase)
                .font(.subheadline)
        }
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Actions Section
struct ActionsSection: View {
    @Binding var showSignOutAlert: Bool
    @Binding var showResetAlert: Bool
    
    var body: some View {
        Section {
            Button(role: .destructive) {
                withAnimation {
                    showSignOutAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(role: .destructive) {
                withAnimation {
                    showResetAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Reset All Data")
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        } header: {
            Text("Account Actions")
                .textCase(.uppercase)
                .font(.subheadline)
        }
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                    .buttonStyle(ScaleButtonStyle())
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
                        withAnimation {
                            authManager.saveProfileImage(image)
                        }
                    }
                }
            ))
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                withAnimation {
                    authManager.signOut()
                    dismiss()
                }
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
