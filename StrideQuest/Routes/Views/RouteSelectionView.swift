import SwiftUI

struct RouteSelectionView: View {
    @EnvironmentObject var routeManager: RouteManager
    @State private var navigateToCompleted = false
    @Environment(\.dismiss) private var dismiss
    var onRouteSelected: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List(availableRoutes) { route in
                NavigationLink(destination: RouteDetailView(
                    route: route,
                    onRouteSelected: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            routeManager.focusMapOnCurrentRoute()
                        }
                    }
                )) {
                    RouteCard(
                        route: route,
                        isAvailable: routeManager.isRouteAvailable(route),
                        isActive: routeManager.currentRoute?.id == route.id,
                        previousRouteName: getPreviousRouteName(for: route)
                    )
                }
                .disabled(!routeManager.isRouteAvailable(route))
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
    
    private func getPreviousRouteName(for route: VirtualRoute) -> String? {
        guard !routeManager.isRouteAvailable(route),
              let currentIndex = routeManager.availableRoutes.firstIndex(where: { $0.id == route.id }),
              currentIndex > 0 else {
            return nil
        }
        return routeManager.availableRoutes[currentIndex - 1].name
    }
}

struct RouteCard: View {
    let route: VirtualRoute
    let isAvailable: Bool
    let isActive: Bool
    let previousRouteName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(route.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
                .overlay {
                    if !isAvailable {
                        Color.black.opacity(0.4)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        if let previousName = previousRouteName {
                            Text("Complete '\(previousName)' to unlock")
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            
            if isActive {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Active Journey")
                }
                .font(.caption)
                .padding(8)
                .background(.green.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(8)
            }
            
            
            VStack(alignment: .leading, spacing: 5) {
                            Text(route.name)
                    .font(.system(.headline, design: .rounded))
                            
                            Text(route.region)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(String(format: "%.1f km", route.totalDistance))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(isAvailable ? 1 : 0.6)
                    }
                    .padding(.vertical, 8)
                }
            }


