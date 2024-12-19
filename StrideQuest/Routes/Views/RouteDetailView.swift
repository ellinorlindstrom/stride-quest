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
    @EnvironmentObject var routeManager: RouteManager
    @Environment(\.dismiss) private var dismiss
    var onRouteSelected: (() -> Void)?
    
    private var isRouteAvailable: Bool {
        routeManager.isRouteAvailable(route)
    }
    
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
                    
                    Text(String(format: "%.1f km", route.totalDistance))
                        .font(.headline)
                    
                    Text(route.description)
                        .font(.body)
                }
                .padding()
                
                Button(action: {
                    routeManager.selectAndStartRoute(route)
                    dismiss()
                    // Give time for the dismiss animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onRouteSelected?()
                    }
                }) {
                    Text(routeManager.currentRoute?.id == route.id ? "Resume Journey" : "Start Journey")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            routeManager.isRouteAvailable(route)
                            ? (routeManager.currentRoute?.id == route.id ? Color.blue : Color.green)
                            : Color.gray
                        )
                        .cornerRadius(10)
                }
                .disabled(!routeManager.isRouteAvailable(route))
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
