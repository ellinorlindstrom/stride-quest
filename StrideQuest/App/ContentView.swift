import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingRouteSelection = false
    @State private var showingManualEntry = false
    @State private var showingProgress = true
    @State private var showingCompletedRoutes = false
    @State private var showingCustomRouteCreation = false
    @State private var showingSettings = false
    @State private var isMenuShowing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated {
                AppHeader(
                    authManager: authManager,
                    showingRouteSelection: $showingRouteSelection,
                    showingManualEntry: $showingManualEntry,
                    showingCompletedRoutes: $showingCompletedRoutes,
                    showingCustomRouteCreation: $showingCustomRouteCreation,
                    showingSettings: $showingSettings,
                    isMenuShowing: $isMenuShowing
                )
                .shadow(radius: 5)
                
                ZStack {
                    MapView()
                    if showingProgress {
                        VStack {
                            Spacer()
                            RouteProgressView()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding()
                        }
                    }
                    if isMenuShowing  {
                        SideMenu(
                            authManager: authManager,
                            showingRouteSelection: $showingRouteSelection,
                            showingManualEntry: $showingManualEntry,
                            showingCompletedRoutes: $showingCompletedRoutes,
                            showingCustomRouteCreation: $showingCustomRouteCreation,
                            showingSettings: $showingSettings,
                            isMenuShowing: $isMenuShowing
                        )
                        .transition(.move(edge: .leading))
                    }
                }
            } else {
                LoginView(authManager: authManager)
            }
        }
        .sheet(isPresented: $showingRouteSelection) {
            RouteSelectionView()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualDistanceEntryView()
        }
        .sheet(isPresented: $showingCompletedRoutes) {
            CompletedRoutesView()
        }
        .sheet(isPresented: $showingCustomRouteCreation) {
            RouteCreationView()
        }
        .sheet(isPresented: $showingSettings) {
        }
        .onAppear {
            authManager.checkAuthentication()
        }
    }
}

