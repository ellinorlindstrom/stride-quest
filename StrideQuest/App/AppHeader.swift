import SwiftUI

struct AppHeader: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var isAnimating = false
    
    let authManager: AuthenticationManager
    @Binding var showingRouteSelection: Bool
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
                    Image(systemName: "map.fill")
                        .font(.title2)
                        .foregroundStyle(.secondSecondarySq)
                }
            }
            
            // App Title
            VStack(alignment: .leading, spacing: 2) {
                Text("StrideQuest")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.textSq)
                Text("Your Adventure Awaits")
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(.textSq)
            }
            
            Spacer()
            
            // Display Today's Distance
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f km", healthManager.totalDistance))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.textSq)
                Text("Today's Distance")
                    .font(.system(.caption2, design: .default))
                    .foregroundStyle(.textSq)
            }
        }
        .padding()
        .background(.backgroundSq)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Fetch distance when AppHeader appears
            healthManager.fetchTotalDistance()
        }
    }
}

extension HealthKitManager {
    static var preview: HealthKitManager {
        let manager = HealthKitManager.shared // Use shared instance if available
        // Set any preview values you want to see
        manager.totalDistance = 5.43 // Example distance
        return manager
    }
}

#Preview {
    AppHeader(
        authManager: AuthenticationManager(),
        showingRouteSelection: .constant(false),
        showingCompletedRoutes: .constant(false),
        showingSettings: .constant(false),
        isMenuShowing: .constant(false)
    )
    .environmentObject(HealthKitManager.preview)
}
// If you want to preview both light and dark mode side by side:
struct AppHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppHeader(
                authManager: AuthenticationManager(),
                showingRouteSelection: .constant(false),
                showingCompletedRoutes: .constant(false),
                showingSettings: .constant(false),
                isMenuShowing: .constant(false)
            )
            .environmentObject(HealthKitManager.preview)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            AppHeader(
                authManager: AuthenticationManager(),
                showingRouteSelection: .constant(false),
                showingCompletedRoutes: .constant(false),
                showingSettings: .constant(false),
                isMenuShowing: .constant(false)
            )
            .environmentObject(HealthKitManager.preview)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
