import SwiftUI
import MapKit
import Combine

// MARK: - Central Route Management
class RouteManager: ObservableObject {
    private static let instance = RouteManager()
        
        static var shared: RouteManager {
            return instance
        }
    
    // MARK: - Published Properties
    @Published private(set) var availableRoutes: [VirtualRoute] = []
    @Published private(set) var currentRoute: VirtualRoute?
    @Published private(set) var currentProgress: RouteProgress?
    @Published private(set) var activeRouteIds: Set<UUID> = []
    @Published private(set) var currentRouteCoordinate: CLLocationCoordinate2D?
    @Published var currentMapRegion: MKCoordinateRegion?
    @Published private(set) var completedRoutes: [RouteProgress] = []
    @Published private(set) var recentlyUnlockedMilestone: RouteMilestone?
    @Published private(set) var progressPolyline: [CLLocationCoordinate2D] = []
    
    // MARK: - Private Properties
    private let healthDataStore = HealthDataStore.shared
    private let milestoneCompletedPublisher = PassthroughSubject<RouteMilestone, Never>()
    
    // MARK: - Milestone State
    @Published var selectedMilestone: RouteMilestone?
    //@Published var showMilestoneCard = false
    @Published var showConfetti = false
    
    var showMilestoneCard: Bool = false {
        willSet {
            print("🔍 showMilestoneCard will change to \(newValue)")
            print("🔍 Called from:")
            Thread.callStackSymbols.forEach { print($0) }
        }
    }
    
    private init() {
            
            // Then load data
            loadRoutes()
            loadCompletedRoutes()
        }
    
    // MARK: - Route Management
    private func loadRoutes() {
        Task {
            let routes = await RouteFactory.initializeRoutes()
            await MainActor.run {
                self.availableRoutes = routes
            }
        }
    }
    
    func selectRoute(_ route: VirtualRoute) {
        currentRoute = route
    }
    
    func beginRouteTracking() {
        guard let selectedRoute = currentRoute else { return }
        
        // Check for existing progress
        let existingProgress = healthDataStore.fetchRouteProgress(for: selectedRoute.id)
        
        if let existingProgress = existingProgress, !existingProgress.isCompleted {
            currentProgress = existingProgress
        } else {
            let progress = RouteProgress(
                id: UUID(),
                routeId: selectedRoute.id,
                startDate: Date(),
                completedDistance: 0,
                lastUpdated: Date(),
                completedMilestones: Set<UUID>(),
                totalDistance: selectedRoute.totalDistance,
                dailyProgress: [:],
                isCompleted: false,
                completionDate: nil
            )
            currentProgress = progress
        }
        
        // Update map and tracking state
        currentRouteCoordinate = selectedRoute.waypoints.first
        updateMapRegion(MKCoordinateRegion(
            center: selectedRoute.startCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        
        HealthKitManager.shared.markRouteStart()
        activeRouteIds.insert(selectedRoute.id)
        updateProgress(withDistance: currentProgress?.completedDistance ?? 0, source: "initial")
        saveProgress()
    }
    
    // MARK: - Progress Polyline Management
        func updateProgressPolyline() {
            guard let progress = currentProgress,
                  let route = currentRoute else {
                progressPolyline = []
                return
            }
            
            var coordinates: [CLLocationCoordinate2D] = []
            var accumulatedDistance: Double = 0
            let targetDistance = progress.completedDistance
            
            print("⚡️ Updating progress polyline")
            print("Total completed distance: \(targetDistance) km")
            
            // Always start with the first coordinate
            if let firstCoord = route.segments.first?.path.first {
                coordinates.append(firstCoord)
            }
            
            // Early exit if we haven't moved from start
            guard targetDistance > 0 else {
                DispatchQueue.main.async {
                    self.progressPolyline = coordinates
                }
                return
            }
            
            outerLoop: for segment in route.segments {
                let segmentCoordinates = segment.path
                
                for i in 0..<(segmentCoordinates.count - 1) {
                    let start = segmentCoordinates[i]
                    let end = segmentCoordinates[i + 1]
                    let pointDistance = RouteUtils.calculateDistance(from: start, to: end)
                    
                    if accumulatedDistance + pointDistance >= targetDistance {
                        // We've found the segment containing our target distance
                        let remainingDistance = targetDistance - accumulatedDistance
                        let fraction = min(1.0, max(0.0, remainingDistance / pointDistance))
                        
                        if let interpolated = RouteUtils.interpolateCoordinate(from: start, to: end, fraction: fraction) {
                            coordinates.append(interpolated)
                        }
                        break outerLoop
                    }
                    
                    coordinates.append(end)
                    accumulatedDistance += pointDistance
                }
            }
            
            DispatchQueue.main.async {
                self.progressPolyline = coordinates
                print("Final polyline has \(coordinates.count) coordinates")
            }
        }
        
        // Update the existing updateProgress function to call updateProgressPolyline
    func updateProgress(withDistance distance: Double, isManual: Bool = false, source: String = "unknown") {
        guard let progress = currentProgress,
              let route = currentRoute,
              activeRouteIds.contains(route.id) else {
            return
        }
        var updatedProgress = progress
        let cappedDistance = min(distance, route.totalDistance)
        
        let todayString = DateFormatter().string(from: Date())
        updatedProgress.updateDailyProgress(distance: distance, for: todayString)
        updatedProgress.updateCompletedDistance(distance, isManual: isManual)
        
        // Update current position
        if let newPosition = route.coordinate(at: cappedDistance) {
            currentRouteCoordinate = newPosition
        }
        
        // Store the current progress before checking new milestones
        currentProgress = updatedProgress
        
        // Only check for new milestones if we haven't already completed them
        if !updatedProgress.completedMilestones.isEmpty {
            print("🎯 Already completed milestones: \(updatedProgress.completedMilestones)")
        }
        checkMilestones(for: updatedProgress, at: cappedDistance)
        
        // Save after all updates
        saveProgress()
        updateProgressPolyline()
    }

    
    
    private func checkMilestones(for progress: RouteProgress, at distance: Double) {
        guard let route = currentRoute else { return }
        
        // Only check milestones that haven't been completed yet
        let uncompletedMilestones = route.milestones
            .filter { !progress.completedMilestones.contains($0.id) }
            .sorted(by: { $0.distanceFromStart < $1.distanceFromStart })
        
        for milestone in uncompletedMilestones {
            if distance >= milestone.distanceFromStart {
                handleMilestoneCompletion(milestone)
            }
        }
    }
    
    // MARK: - Milestone Management
    func handleMilestoneCompletion(_ milestone: RouteMilestone) {
        guard let progress = currentProgress else {
            print("❌ No current progress found")
            return
        }
        
        print("🎯 Before completion - Completed milestones: \(progress.completedMilestones)")
        
        // Create new progress instance with updated milestones
        var updatedProgress = progress
        updatedProgress.addCompletedMilestone(milestone.id)
        
        // Important: Update the current progress
        currentProgress = updatedProgress
        
        // Save immediately to persist the change
        saveProgress()
        
        print("🎯 After completion - Completed milestones: \(updatedProgress.completedMilestones)")
        
        recentlyUnlockedMilestone = milestone
        milestoneCompletedPublisher.send(milestone)
        
        // Only show UI if milestone was just completed
        DispatchQueue.main.async {
            self.selectedMilestone = milestone
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showMilestoneCard = true
                self.showConfetti = true
            }
        }
        
        // Check if route is completed
        if progress.isCompleted {
            handleRouteCompletion(progress)
        }
    }
    
    func isMilestoneCompleted(_ milestone: RouteMilestone) -> Bool {
        let isCompleted = currentProgress?.completedMilestones.contains(milestone.id) ?? false
        print("🎯 Checking milestone completion for \(milestone.name)")
        print("🎯 Current progress completed milestones: \(currentProgress?.completedMilestones ?? [])")
        print("🎯 Is completed: \(isCompleted)")
        return isCompleted
    }
    
    // MARK: - Route Completion
     func handleRouteCompletion(_ progress: RouteProgress) {
        guard progress.isCompleted else { return }
            
            let routeId = progress.routeId 
            
        
        DispatchQueue.main.async {
            self.activeRouteIds.remove(routeId)
            
            if !self.completedRoutes.contains(where: { $0.routeId == routeId }) {
                self.completedRoutes.append(progress)
                self.healthDataStore.updateRouteProgress(progress)
            }
            
            self.currentProgress = nil
            self.currentRoute = nil
        }
    }
    
    // MARK: - Utility Functions
    
    // In RouteManager class
    func getRoute(by id: UUID) -> VirtualRoute? {
        return availableRoutes.first { route in route.id == id }
    }
    
    private func loadCompletedRoutes() {
        let fetchedRoutes = healthDataStore.fetchAllRouteProgress().filter { $0.isCompleted }
        DispatchQueue.main.async {
            self.completedRoutes = fetchedRoutes
        }
    }
    
    func saveProgress() {
        if let progress = currentProgress {
            healthDataStore.updateRouteProgress(progress)
        }
    }
    
    func updateMapRegion(_ region: MKCoordinateRegion) {
        currentMapRegion = region
    }
    
    func isTracking(route: VirtualRoute) -> Bool {
        activeRouteIds.contains(route.id)
    }
    func isRouteCompleted(_ routeId: UUID) -> Bool {
            completedRoutes.contains { $0.routeId == routeId }
        }
}
