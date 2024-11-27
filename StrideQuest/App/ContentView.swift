import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingRouteSelection = false
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var showingProgress = true
    @State private var showingHealthKitAuth = false
    @State private var camera = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),distance: 1000)
        
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ZStack {
                    MapView(position: $position)
                    
                    VStack {
                        HStack {
                            Menu {
                                Button("Routes", action: { showingRouteSelection = true })
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
                            
                            Spacer()
                  
                        }

                        Spacer()
                        
                        // Progress View
                        if showingProgress {
                            RouteProgressView()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding()
                        }
                    }
                }
                .task {
                    // Request HealthKit authorization if needed
                    if !healthManager.isAuthorized {
                        do {
                            try await healthManager.requestAuthorization()
                        } catch {
                            showingHealthKitAuth = true
                        }
                    }
                }
                .alert("HealthKit Access Required", isPresented: $showingHealthKitAuth) {
                    Button("Open Settings", role: .none) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This app needs access to HealthKit to track your progress.")
                }
                .onReceive(routeManager.$currentRouteCoordinate) { coordinate in
                                    if let coordinate = coordinate {
                                        withAnimation {
                                            position = .region(MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
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
    
    // Helper function to get coordinate for milestone
    private func getCoordinate(for milestone: RouteMilestone, in route: VirtualRoute) -> CLLocationCoordinate2D? {
        // This should be implemented based on your route coordinate system
        // For now, returning nil
        return nil
    }
}

// Custom transition for the progress view
extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager.shared)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
