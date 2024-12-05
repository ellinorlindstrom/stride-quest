//
//  RouteSelectionView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-26.
//

import SwiftUI

struct RouteSelectionView: View {
    @StateObject private var routeManager = RouteManager.shared
    @Environment(\.dismiss) private var dismiss
    var onRouteSelected: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List(routeManager.availableRoutes) { route in
                NavigationLink(destination: RouteDetailView(route: route)) {
                                    RouteCard(route: route)
                                }
                            }
                            .navigationTitle("Choose Your Journey")
                        }
    }
}

struct RouteCard: View {
    let route: VirtualRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(route.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(route.name)
                    .font(.headline)
                
                Text(route.region)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(String(format: "%.1f km", route.totalDistance / 1000))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    RouteSelectionView()
}
