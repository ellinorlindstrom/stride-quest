import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authManager = AuthenticationManager()
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                
                Map (position: $position) {
                    UserAnnotation()
                        
                    
                }
                .environmentObject(healthManager)
                .mapControls{
                    MapUserLocationButton()
                    MapPitchToggle()
                    MapCompass()
                }
                .mapStyle(.standard(elevation: .realistic))
                .overlay(alignment: .topLeading) {
                    
                        Button("Sign Out") {
                        authManager.signOut()
                    }
                        .padding()

                }
                .overlay(alignment: .bottom) {
                    VStack {
                        ActivityView()
                            .padding()
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
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
