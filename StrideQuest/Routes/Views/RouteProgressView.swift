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
    @Binding var isLoading: Bool
    
    var body: some View {
        if !isLoading {
            VStack(spacing: 20) {
                if let progress = routeManager.currentProgress,
                   let route = routeManager.getRoute(by: progress.routeId) {
                    // Current route progress
                    VStack(alignment: .leading, spacing: 15) {
                        Text(route.name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.textSq)
                        
                        ProgressBar(value: progress.percentageCompleted)
                            .id(healthManager.totalDistance)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Completed")
                                Text(String(format: "%.2f km", healthManager.totalDistance))
                                    .font(.headline)
                                    .foregroundStyle(.textSq)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Remaining")
                                Text(String(format: "%.2f km",
                                            max(0,route.totalDistance - healthManager.totalDistance)))
                                .font(.headline)
                                .foregroundStyle(.textSq)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    
                } else {
                    VStack(spacing: 5) {
                        Text("No Active Journey")
                            .font(.system(.headline, design: .rounded))
                            .padding()
                            .foregroundStyle(.textSq)
                        
                        Button("Choose Your Adventure!") {
                            routeManager.showingRouteSelection = true
                        }
                        .font(.system(.caption, design: .rounded))
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .tint(.secondSecondarySq)
                        
                    }
                }
            }
            if isLoading {
                LoadingView()
                    .zIndex(100)
            }
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
                    .foregroundStyle(.backgroundSq)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width / 100, geometry.size.width),
                           height: 20)
                    .foregroundStyle(.secondarySq)
                    .animation(.spring(), value: value)
            }
            .cornerRadius(10)
        }
        .frame(height: 20)
    }
}

