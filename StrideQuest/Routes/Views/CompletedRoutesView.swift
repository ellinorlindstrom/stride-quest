//
//  CompletedRoutesView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-30.
//
import Foundation
import SwiftUI

struct CompletedRoutesView: View {
    @EnvironmentObject var routeManager: RouteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingRouteSelection = false
    
//    private func debugLog() {
//            print("\n📱 CompletedRoutesView Debug Info:")
//            print("  - Total completed routes: \(routeManager.completedRoutes.count)")
//            
//            for (index, progress) in routeManager.completedRoutes.enumerated() {
//                print("\n  Route \(index + 1):")
//                print("    - Progress ID: \(progress.id)")
//                print("    - Route ID: \(progress.routeId)")
//                print("    - Has current route?: \(progress.currentRoute != nil)")
//                print("    - Completed Distance: \(progress.completedDistance)")
//                print("    - Is Completed: \(progress.isCompleted)")
//                if let route = progress.currentRoute {
//                    print("    - Route name: \(route.name)")
//                }
//            }
//        }
        
        var body: some View {
            NavigationStack {
                ZStack {
                    if routeManager.completedRoutes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "flag.checkered.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Completed Routes Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Your completed journeys will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Start a New Journey") {
                                showingRouteSelection = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .padding(.top)
                        }
                        .padding()
                        .multilineTextAlignment(.center)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(routeManager.completedRoutes, id: \.id) { progress in
                                    if let route = routeManager.getRoute(by: progress.routeId) {
                                        CompletedRouteCard(route: route, progress: progress)
                                    } else {
                                        Text("Invalid Route (ID: \(progress.routeId))")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Completed Journeys")
                .sheet(isPresented: $showingRouteSelection) {
                    RouteSelectionView(onRouteSelected: {
                        dismiss()
                    })
                }
            }
//            .onAppear {
//                debugLog()
//            }
        }
    }

struct CompletedRouteCard: View {
    let route: VirtualRoute
    let progress: RouteProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Route Image
            Image(route.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
            
            // Route Details
            VStack(alignment: .leading, spacing: 8) {
                Text(route.name)
                    .font(.headline)
                
                Text(route.region)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Completion Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed on: \(formatDate(progress.completionDate ?? Date()))")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Distance: \(String(format: "%.1f km", progress.completedDistance))")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Duration: \(formatDuration(from: progress.startDate, to: progress.completionDate ?? Date()))")
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .hour], from: start, to: end)
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "Less than an hour"
    }
}
