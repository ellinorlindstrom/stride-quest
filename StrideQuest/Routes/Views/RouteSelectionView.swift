import SwiftUI

struct RouteSelectionView: View {
    @EnvironmentObject var routeManager: RouteManager
    @State private var navigateToCompleted = false
    @Environment(\.dismiss) private var dismiss
    var onRouteSelected: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List(availableRoutes) { route in // Use the filtered list here
                NavigationLink(destination: RouteDetailView(route: route, onRouteSelected: {
                    onRouteSelected?()
                    dismiss()
                })) {
                    RouteCard(route: route)
                }
            }
            .navigationTitle("Choose Your Journey")
            .navigationDestination(isPresented: $navigateToCompleted) {
                CompletedRoutesView()
            }
        }
        .onReceive(routeManager.$completedRoutes) { _ in
            // When completedRoutes updates, check if we should navigate
            if let currentProgress = routeManager.currentProgress,
               currentProgress.isCompleted {
                navigateToCompleted = true
            }
        }
    }
    
    var availableRoutes: [VirtualRoute] {
        routeManager.availableRoutes.filter { route in
            !routeManager.isRouteCompleted(route.id)
        }
    }
}

struct RouteCard: View {
    let route: VirtualRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(route.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(route.name)
                    .font(.system(.headline, design: .monospaced))
                
                Text(route.region)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(String(format: "%.1f km", route.totalDistance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    RouteSelectionView()
}
