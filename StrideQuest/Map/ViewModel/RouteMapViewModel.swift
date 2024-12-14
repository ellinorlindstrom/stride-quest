////
////  RouteMapViewModel.swift
////  StrideQuest
////
////  Created by Ellinor Lindström on 2024-12-14.
////
//import MapKit
//import SwiftUI
//
//@MainActor
//class RouteMapViewModel: ObservableObject {
//    @Published var selectedMilestone: RouteMilestone?
//    @Published var showingMilestoneCard = false
//    @Published var currentPosition: CLLocationCoordinate2D?
//    @Published private(set) var progressPath: [CLLocationCoordinate2D] = []
//    
//    let routeManager: RouteManager
//    
//    init(routeManager: RouteManager) {
//        self.routeManager = routeManager
//        setupSubscriptions()
//    }
//    
//    var currentRoute: VirtualRoute? {
//        routeManager.currentProgress?.currentRoute
//    }
//    
//    var currentProgress: RouteProgress? {
//        routeManager.currentProgress
//    }
//    
//    func handleMilestoneSelected(_ milestone: RouteMilestone) {
//        guard isMilestoneCompleted(milestone) else { return }
//        
//        selectedMilestone = milestone
//        withAnimation {
//            showingMilestoneCard = true
//        }
//    }
//    
//    func isMilestoneCompleted(_ milestone: RouteMilestone) -> Bool {
//        routeManager.isMilestoneCompleted(milestone)
//    }
//    
//    func setInitialCamera() {
//        guard let route = currentRoute else { return }
//        
//        // Set the initial region to show the entire route
//        let coordinates = route.fullPath
//        var minLat = coordinates[0].latitude
//        var maxLat = coordinates[0].latitude
//        var minLon = coordinates[0].longitude
//        var maxLon = coordinates[0].longitude
//        
//        for coordinate in coordinates {
//            minLat = min(minLat, coordinate.latitude)
//            maxLat = max(maxLat, coordinate.latitude)
//            minLon = min(minLon, coordinate.longitude)
//            maxLon = max(maxLon, coordinate.longitude)
//        }
//        
//        let center = CLLocationCoordinate2D(
//            latitude: (minLat + maxLat) / 2,
//            longitude: (minLon + maxLon) / 2
//        )
//        
//        let span = MKCoordinateSpan(
//            latitudeDelta: (maxLat - minLat) * 1.5,
//            longitudeDelta: (maxLon - minLon) * 1.5
//        )
//        
//        routeManager.updateMapRegion(MKCoordinateRegion(center: center, span: span))
//    }
//    
//    func updateProgressPath() {
//        guard let progress = currentProgress,
//              let route = currentRoute else {
//            progressPath = []
//            return
//        }
//        
//        let percentComplete = progress.completedDistance / route.totalDistance  // These are now in km
//        
//        if percentComplete <= 0 {
//            progressPath = []
//        } else if percentComplete >= 1 {
//            progressPath = route.waypoints
//        } else {
//            // Calculate intermediate point
//            let totalDistance = route.totalDistance  // In km
//            let targetDistance = progress.completedDistance  // In km
//            var accumulatedDistance = 0.0  // In km
//            var result: [CLLocationCoordinate2D] = []
//            
//            for i in 0..<(route.waypoints.count - 1) {
//                let start = route.waypoints[i]
//                let end = route.waypoints[i + 1]
//                let segmentDistance = start.distance(to: end)  // Already in km thanks to your extension
//                
//                if accumulatedDistance + segmentDistance > targetDistance {
//                    // Interpolate between points
//                    let remainingDistance = targetDistance - accumulatedDistance
//                    let fraction = remainingDistance / segmentDistance
//                    let interpolatedLat = start.latitude + (end.latitude - start.latitude) * fraction
//                    let interpolatedLon = start.longitude + (end.longitude - start.longitude) * fraction
//                    
//                    result.append(CLLocationCoordinate2D(
//                        latitude: interpolatedLat,
//                        longitude: interpolatedLon
//                    ))
//                    break
//                } else {
//                    result.append(start)
//                    accumulatedDistance += segmentDistance
//                }
//            }
//            
//            progressPath = result
//            currentPosition = result.last
//        }
//    }
//    
//    private func setupSubscriptions() {
//        // Add any necessary Combine subscriptions here
//    }
//}
