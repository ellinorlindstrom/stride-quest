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
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ZStack {
                    MapView()
                    
                    VStack {
                        HStack {
                            Menu {
                                Button("Routes", action: { showingRouteSelection = true })
                                Button("Add Distance Manually") { showingManualEntry = true }
                                Button("Completed Routes") { showingCompletedRoutes = true }
                                Button("Sign Out", action: authManager.signOut)
                            } label: {
                                Image(systemName: "line.horizontal.3")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .padding()
                                    .bold()
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
                            
                            Spacer()
                        }

                        Spacer()
                        
                        if showingProgress {
                            RouteProgressView()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding()
                        }
                    }
                }
            } else {
                LoginView(authManager: authManager)
            }
        }
        .onAppear {
            authManager.checkAuthentication()
        }
    }
}


#Preview {
    ContentView()
}
