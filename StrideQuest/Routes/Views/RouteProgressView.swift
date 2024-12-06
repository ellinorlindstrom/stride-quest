//
//  RouteProgressView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-26.
//

import SwiftUI

struct RouteProgressView: View {
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var showingRouteSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let progress = routeManager.currentProgress,
               let route = progress.currentRoute {
                // Current route progress
                VStack(alignment: .leading, spacing: 15) {
                    Text(route.name)
                        .font(.headline)
                    
                    ProgressBar(value: progress.percentageCompleted)
                        .id(progress.completedDistance)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Completed")
                            Text(String(format: "%.2f km", progress.completedDistance))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Remaining")
                            Text(String(format: "%.1f km",
                                        (route.totalDistance / 1000) - progress.completedDistance))
                                .font(.headline)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
             
            } else {
                VStack(spacing: 5) {
                    Text("No Active Journey")
                        .font(.headline)
                        .padding()
                    
                    Button("Choose Your Adventure!") {
                        showingRouteSelection = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .tint(.green)
                    
                }
            }
        }
        .sheet(isPresented: $showingRouteSelection) {
            RouteSelectionView()
        }
    }
}

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 20)
                    .opacity(0.3)
                    .foregroundStyle(.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width / 100, geometry.size.width),
                           height: 20)
                    .foregroundStyle(.blue)
                    .animation(.spring(), value: value)
            }
            .cornerRadius(10)
        }
        .frame(height: 20)
    }
}

struct MilestoneCard: View {
    @ObservedObject private var routeManager = RouteManager.shared
    let milestone: RouteMilestone
    
    var body: some View {
        VStack {
            Image(milestone.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(routeManager.isMilestoneCompleted(milestone) ? Color.green : Color.gray, lineWidth: 4)
                )
            
            Text(milestone.name)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            if routeManager.isMilestoneCompleted(milestone) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 120)
    }
}
