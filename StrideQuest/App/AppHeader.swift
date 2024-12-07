import SwiftUI

struct AppHeader: View {
    @State private var isAnimating = false
    //@State private var showMenu = false
    let authManager: AuthenticationManager
    @Binding var showingRouteSelection: Bool
    @Binding var showingManualEntry: Bool
    @Binding var showingCompletedRoutes: Bool
    @Binding var isMenuShowing: Bool
    
    var body: some View {
        
            HStack(spacing: 12) {
                // Logo/Icon with Menu Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                        isMenuShowing.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundStyle(.teal)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .onAppear {
                                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                                    isAnimating = true
                                }
                            }
                    }
                }
                
                // App Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("StrideQuest")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                    Text("Your Adventure Awaits")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int.random(in: 1...10))K")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.teal)
                    Text("Steps Today")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .frame(maxWidth: .infinity)
        }
    }

