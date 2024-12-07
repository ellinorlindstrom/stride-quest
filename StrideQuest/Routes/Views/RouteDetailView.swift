//
//  Untitled.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-26.
//

import SwiftUI
import Foundation

struct RouteDetailView: View {
    let route: VirtualRoute
    @StateObject private var routeManager = RouteManager.shared
    @Environment(\.dismiss) private var dismiss
    var onRouteSelected: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route image
                Image(route.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                
                // Route details
                VStack(alignment: .leading, spacing: 15) {
                    Text(route.name)
                        .font(.system(.title, design: .monospaced))
                        .bold()
                    
                    Text(route.region)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f km", route.totalDistance / 1000))
                        .font(.headline)
                    
                    Text(route.description)
                        .font(.body)
                }
                .padding()
                
                // Start button
                if !routeManager.isActivelyTracking {
                    Button(action: {
                        routeManager.selectRoute(route)
                        routeManager.beginRouteTracking()
                        dismiss()
                        onRouteSelected?()
                    }) {
                        Text("Start Journey")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
