//
//  ContentView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Map{
            if let location = locationManager.location {
                Marker("My location", coordinate: location.coordinate)
                    .tint(.blue)
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            }
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdatingLocation()
            }
        }
    }

#Preview {
    ContentView()
}
