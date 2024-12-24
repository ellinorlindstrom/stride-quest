//
//  ManualDistanceEntryView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-27.
//

import SwiftUI
import Foundation

struct ManualDistanceEntryView: View {
    @EnvironmentObject var routeManager: RouteManager
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var additionalDistance = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Additional distance in kilometers", text: $additionalDistance)
                        .keyboardType(.decimalPad)
                        .onChange(of: additionalDistance) { _, newValue in
                            let formatted = newValue.replacingOccurrences(of: ",", with: ".")
                            if let _ = Double(formatted) {
                                additionalDistance = formatted
                            } else if newValue.isEmpty {
                                additionalDistance = ""
                            } else {
                                additionalDistance = String(additionalDistance.dropLast())
                            }
                        }
                }
                
                Button("Add Distance") {
                    if let km = Double(additionalDistance) {
                        // Update HealthKit's total distance
                        let newTotalDistance = healthManager.totalDistance + km
                        healthManager.totalDistance = newTotalDistance
                        
                        // Update route progress
                        routeManager.updateProgress(withDistance: newTotalDistance, isManual: true)
                        dismiss()
                    }
                }
                .disabled(Double(additionalDistance) == nil)
            }
            .navigationTitle("Add Distance")
        }
    }
}
