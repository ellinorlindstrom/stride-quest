//
//  CompletedRoutesView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-30.
//
import Foundation
import SwiftUI

struct CompletedRoutesView: View {
    @ObservedObject private var routeManager = RouteManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingRouteSelection = false
    
    var body: some View {
        NavigationView {
            Group {
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
                    .sheet(isPresented: $showingRouteSelection) {
                        RouteSelectionView(onRouteSelected: {
                            dismiss()
                        })
                    }
                    .padding()
                    .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(routeManager.completedRoutes, id: \.id) { progress in
                            if let route = progress.currentRoute {
                                CompletedRouteCard(route: route, progress: progress)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Completed Journeys")
        }
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
