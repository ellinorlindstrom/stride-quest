//
//  ManualDistanceEntryView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-27.
//

import SwiftUI
import Foundation

struct ManualDistanceEntryView: View {
    @ObservedObject var routeManager = RouteManager.shared
    @State private var distance: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Distance in kilometers", text: $distance)
                        .keyboardType(.decimalPad)
                }
                
                Button("Add Distance") {
                    if let km = Double(distance) {
                        routeManager.updateProgress(withDistance: km)
                        dismiss()
                    }
                }
                .disabled(Double(distance) == nil)
            }
            .navigationTitle("Add Manual Distance")
        }
    }
}
