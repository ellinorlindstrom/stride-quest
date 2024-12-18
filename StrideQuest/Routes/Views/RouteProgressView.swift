//
//  RouteProgressView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-26.
//

import SwiftUI

struct RouteProgressView: View {
    @EnvironmentObject var routeManager: RouteManager
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var showingRouteSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let progress = routeManager.currentProgress,
               let route = progress.currentRoute {
                // Current route progress
                VStack(alignment: .leading, spacing: 15) {
                    Text(route.name)
                        .font(.system(.headline, design: .monospaced))
                    
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
                            Text(String(format: "%.2f km",
                                        route.totalDistance - progress.completedDistance))
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
                        .font(.system(.headline, design: .monospaced))
                        .padding()
                    
                    Button("Choose Your Adventure!") {
                        showingRouteSelection = true
                    }
                    .font(.system(.caption, design: .monospaced))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .tint(.teal)
                    
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

