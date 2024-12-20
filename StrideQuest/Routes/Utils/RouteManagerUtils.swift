//
//  RouteRestore.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-19.
//

import SwiftUI
import Foundation

// MARK: - RouteManager+StatePersistence
extension RouteManager {
    private enum UserDefaultsKeys {
        static let currentRouteId = "currentRouteId"
        static let isActivelyTracking = "isActivelyTracking"
    }
    
    
    /// Restores the previous state of the RouteManager from persistent storage
    func restoreState() {
        restoreCurrentRouteAndProgress()
        // Restore tracking state
        isActivelyTracking = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isActivelyTracking)
        if isActivelyTracking {
            HealthKitManager.shared.isTrackingRoute = true
        }
        restoreMilestoneState()
    }
    
    private func restoreCurrentRouteAndProgress() {
        guard let savedRouteIdString = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentRouteId),
              let savedRouteId = UUID(uuidString: savedRouteIdString) else {
            return
        }
        
        Task {
            let routes = await RouteFactory.initializeRoutes()
            await MainActor.run {
                self.setAvailableRoutes(routes)
                self.setCurrentRoute(routes.first { $0.id == savedRouteId })
                
                if let progress = healthDataStore.fetchRouteProgress(for: savedRouteId) {
                    self.setCurrentProgress(progress)
                    self.updateProgressPolyline()
                    
                    if let route = self.currentRoute {
                        for milestone in route.milestones where progress.completedMilestones.contains(milestone.id) {
                            self.setRecentlyUnlockedMilestone(nil)
                        }
                    }
                }
            }
        }
    }
    
    private func restoreMilestoneState() {
        guard let progress = currentProgress,
              let route = currentRoute else { return }
        
        print("🔄 Restoring milestone states")
        print("  - Current progress: \(progress.completedDistance) km")
        print("  - Completed milestones: \(progress.completedMilestones)")
        
        // Force check all milestones based on saved progress
        for milestone in route.milestones {
            if progress.completedMilestones.contains(milestone.id) ||
               milestone.distanceFromStart <= progress.completedDistance {
                // Either the milestone was explicitly marked as completed
                // or the distance indicates it should be completed
                if !progress.completedMilestones.contains(milestone.id) {
                    var updatedProgress = progress
                    updatedProgress.addCompletedMilestone(milestone.id)
                    self.setCurrentProgress(updatedProgress)
                    saveProgress()
                }
            }
        }
    }
    
    /// Saves the current state of the RouteManager to persistent storage
    func saveState() {
        saveCurrentRoute()
        UserDefaults.standard.set(isActivelyTracking, forKey: UserDefaultsKeys.isActivelyTracking)
        
    }
    
    private func saveCurrentRoute() {
        if let currentRoute = currentRoute {
            UserDefaults.standard.set(currentRoute.id.uuidString, forKey: UserDefaultsKeys.currentRouteId)
        } else {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.currentRouteId)
        }
    }
}

// MARK: - RouteManager+ProgressTracking
extension RouteManager {
    func initializeProgress(for route: VirtualRoute) -> RouteProgress {
        RouteProgress(
            id: UUID(),
            routeId: route.id,
            startDate: Date(),
            completedDistance: 0,
            lastUpdated: Date(),
            completedMilestones: Set<UUID>(),
            totalDistance: route.totalDistance,
            dailyProgress: [:],
            isCompleted: false,
            completionDate: nil
        )
    }
    
    func resumeExistingProgress(for route: VirtualRoute) {
        if let existingProgress = healthDataStore.fetchRouteProgress(for: route.id),
           !existingProgress.isCompleted {
            self.setCurrentProgress(existingProgress)
            
            // Don't show milestone cards for already completed milestones
            for milestone in route.milestones where existingProgress.completedMilestones.contains(milestone.id) {
                self.setRecentlyUnlockedMilestone(nil)
            }
        } else {
            self.setCurrentProgress(initializeProgress(for: route))
        }
    }
    
    func startTracking() {
        guard let selectedRoute = currentRoute else {
            print("❌ No route selected for tracking")
            return
        }
        
        print("🎯 Starting tracking for route: \(selectedRoute.name)")
        
        // Ensure tracking state is set
        isActivelyTracking = true
        
        resumeExistingProgress(for: selectedRoute)
        saveState()
        saveProgress()
        
        print("💾 State and progress saved")
        
        HealthKitManager.shared.markRouteStart()
        print("🏃‍♂️ Route start marked")
        
        // Force an immediate distance fetch
        HealthKitManager.shared.fetchTotalDistance()
    }
}
