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
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                Map (position: $position) {
                    UserAnnotation()
                    
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
