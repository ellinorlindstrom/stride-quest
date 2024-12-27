import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var routeManager: RouteManager
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingProgress = true
    @State private var showingCompletedRoutes = false
    @State private var showingSettings = false
    @State private var isMenuShowing = false
    @State private var isLoading = true
    @State private var hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
    
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated {
                if !hasSeenWelcome {
                    WelcomeView(onCompletion: {
                        hasSeenWelcome = true
                        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                        Task {
                            try? await healthManager.requestAuthorization()
                            authManager.requestNotificationPermissions()
                        }
                    })
                } else {
                    VStack(spacing: 0) {
                        AppHeader(
                            authManager: authManager,
                            showingRouteSelection: $routeManager.showingRouteSelection,
                            showingCompletedRoutes: $showingCompletedRoutes,
                            showingSettings: $showingSettings,
                            isMenuShowing: $isMenuShowing
                        )
                        .shadow(radius: 5)
                        
                        ZStack {
                            MapView(isLoading: $isLoading)
                                .environmentObject(routeManager)
                            if showingProgress {
                                VStack {
                                    Spacer()
                                    RouteProgressView(isLoading: $isLoading)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(15)
                                        .padding()
                                }
                            }
                            if isMenuShowing {
                                SideMenu(
                                    authManager: authManager,
                                    showingRouteSelection: $routeManager.showingRouteSelection,
                                    showingCompletedRoutes: $showingCompletedRoutes,
                                    showingSettings: $showingSettings,
                                    isMenuShowing: $isMenuShowing
                                )
                                .environmentObject(authManager)
                                .transition(.move(edge: .leading))
                            }
                        }
                    }
                }
            } else {
                LoginView(authManager: authManager)
            }
        }
        .sheet(isPresented: $routeManager.showingRouteSelection) {
            RouteSelectionView()
                .environmentObject(routeManager)
        }
        .sheet(isPresented: $showingCompletedRoutes) {
            CompletedRoutesView()
                .environmentObject(routeManager)
        }
        
        .sheet(isPresented: $showingSettings) {
            SettingsView(authManager: authManager )
        }
        .onAppear {
            authManager.checkAuthentication()
        }
        .onChange(of: authManager.activeNotification) { oldNotification, notification in
            guard let notification = notification else { return }
            
            switch notification.type {
            case "milestone":
                if let milestone = routeManager.currentRoute?.milestones.first(where: { $0.id.uuidString == notification.id }) {
                    routeManager.selectedMilestone = milestone
                    routeManager.showMilestoneCard = true
                }
            default:
                break
            }
            // Reset the active notification after handling
            authManager.activeNotification = nil
        }
    }
}


