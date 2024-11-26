//
//  HealthStatsView.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-26.
//

import SwiftUI
import HealthKit

struct ActivityView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        VStack {
            if healthKitManager.isAuthorized {
                Text("Today's Distance")
                    .font(.headline)
                Text(String(format: "%.2f km", healthKitManager.totalDistance / 1000))
                    .font(.title)
            } else {
                Button("Authorize HealthKit")
                {
                    Task {
                        try? await healthKitManager.requestAuthorization()
                    }
                }
            }
        }
        .onAppear {
            if healthKitManager.isAuthorized {
                healthKitManager.fetchTotalDistance()
            }
        }
    }
}

#Preview {
    ActivityView()
}
