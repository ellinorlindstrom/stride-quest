import SwiftUI

struct AppHeader: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var isAnimating = false
    
    let authManager: AuthenticationManager
    @Binding var showingRouteSelection: Bool
    @Binding var showingManualEntry: Bool
    @Binding var showingCompletedRoutes: Bool
    @Binding var showingSettings: Bool
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
                        .foregroundStyle(.primarySq)
                }
            }
            
            // App Title
            VStack(alignment: .leading, spacing: 2) {
                Text("StrideQuest")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.accentSq)
                Text("Your Adventure Awaits")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.textSq)
            }
            
            Spacer()
            
            // Display Today's Distance
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f km", healthManager.totalDistance))
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.accentSq)
                Text("Today's Distance")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.textSq)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Fetch distance when AppHeader appears
            healthManager.fetchTotalDistance()
        }
    }
}
