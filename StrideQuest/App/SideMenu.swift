import SwiftUI

struct SideMenu: View {
    @GestureState private var dragOffset: CGFloat = 0
    let authManager: AuthenticationManager
    @Binding var showingRouteSelection: Bool
    @Binding var showingManualEntry: Bool
    @Binding var showingCompletedRoutes: Bool
    @Binding var isMenuShowing: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black
                    .opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                            isMenuShowing = false
                        }
                    }
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            Text("Welcome")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 25)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial.opacity(0.7))
                        
                        // Menu Items
                        VStack(spacing: 0) {
                            MenuButton(icon: "map.fill", title: "Routes") {
                                showingRouteSelection = true
                                isMenuShowing = false
                            }
                            
                            MenuButton(icon: "plus.circle.fill", title: "Add Distance") {
                                showingManualEntry = true
                                isMenuShowing = false
                            }
                            
                            MenuButton(icon: "checkmark.circle.fill", title: "Completed Routes") {
                                showingCompletedRoutes = true
                                isMenuShowing = false
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            MenuButton(icon: "arrow.right.square.fill", title: "Sign Out") {
                                authManager.signOut()
                                isMenuShowing = false
                            }
                        }
                        .padding(.vertical, 8)
                        .font(.system(.headline, design: .monospaced))
                        
                        Spacer()
                    }
                    .frame(width: min(geometry.size.width * 0.8, 300))
                    .background(.ultraThinMaterial.opacity(0.7))
                    .offset(x: dragOffset)
                    
                    Spacer()
                }
            }
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.width < 0 {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isMenuShowing = false
                        }
                    }
                }
        )
    }
}
struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 24)
                Text(title)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .foregroundStyle(.primary)
    }
}

