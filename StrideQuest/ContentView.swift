//
//  ContentView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var locationManager: LocationManager
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    
    init() {
        let container = PersistenceController.shared.container
        _locationManager = StateObject(wrappedValue: LocationManager(container: container))
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                Map (position: $position) {
                    UserAnnotation()
                    
                    if !locationManager.currentRoute.isEmpty {
                                        MapPolyline(coordinates: locationManager.currentRoute)
                                            .stroke(.blue, lineWidth: 4)
                                    }
                }
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
                        Button(locationManager.isTracking ? "Stop Tracking" : "Start Tracking") {
                            if locationManager.isTracking {
                                locationManager.stopTracking()
                            } else {
                                locationManager.startTracking()
                            }
                        }
                        .padding()
                        .background(locationManager.isTracking ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding()
                    }
                }
            } else {
                LoginView(authManager: authManager)  
            }
        }
        .onAppear {
            authManager.checkAuthentication()
            locationManager.requestPermission()
        }
    }
}

        

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
