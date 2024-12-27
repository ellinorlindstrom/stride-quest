import SwiftUI
import MapKit
import Combine

// MARK: - Central Route Management
class RouteManager: ObservableObject {
    @Published var isActivelyTracking: Bool = false
    // MARK: - Published Properties
    @Published private(set) var availableRoutes: [VirtualRoute] = []
    @Published private(set) var currentRoute: VirtualRoute?
    @Published private(set) var currentProgress: RouteProgress?
    @Published private(set) var currentRouteCoordinate: CLLocationCoordinate2D?
    @Published private(set) var currentMapRegion: MKCoordinateRegion?
    @Published private(set) var completedRoutes: [RouteProgress] = []
    @Published private(set) var recentlyUnlockedMilestone: RouteMilestone?
    @Published private(set) var progressPolyline: [CLLocationCoordinate2D] = []
    @Published var showingRouteSelection: Bool = false
    
    internal func setAvailableRoutes(_ routes: [VirtualRoute]) {
        availableRoutes = routes
    }
    
    internal func setCurrentRoute(_ route: VirtualRoute?) {
        currentRoute = route
    }
    
    internal func setCurrentProgress(_ progress: RouteProgress?) {
        currentProgress = progress
    }
    
    internal func setRecentlyUnlockedMilestone(_ milestone: RouteMilestone?) {
        recentlyUnlockedMilestone = milestone
    }
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let milestoneCompletedPublisher = PassthroughSubject<RouteMilestone, Never>()
    
    private static let instance = RouteManager()
    
    static var shared: RouteManager {
        return instance
    }
    
    private init() {
        Task {
            await restoreState()
        }
        loadRoutes()
        loadCompletedRoutes()
    }
    
    let healthDataStore = HealthDataStore.shared
    
    // MARK: - Milestone State
    @Published var selectedMilestone: RouteMilestone?
    //@Published var showMilestoneCard = false
    @Published var showConfetti = false
    
    var showMilestoneCard: Bool = false {
        willSet {
            print("🔍 showMilestoneCard will change to \(newValue)")
        }
    }
    
    func selectAndStartRoute(_ route: VirtualRoute) {
        guard isRouteAvailable(route) else {
            print("❌ Route not available")
            return
        }
        
        // Set tracking state first
        isActivelyTracking = true
        
        // Set the current route
        setCurrentRoute(route)
        
        // Initialize fresh progress
        let newProgress = initializeProgress(for: route)
        setCurrentProgress(newProgress)
        
        // Start HealthKit tracking
        HealthKitManager.shared.markRouteStart()
        
        print("🎯 Initial milestone check with distance: \(HealthKitManager.shared.totalDistance)")
        let currentDistance = HealthKitManager.shared.totalDistance
        for milestone in route.milestones {
            if milestone.distanceFromStart <= currentDistance {
                // Only add if not already completed
                if !newProgress.completedMilestones.contains(milestone.id) {
                    handleMilestoneCompletion(milestone)
                    print("🎯 Restored milestone: \(milestone.name) at distance \(milestone.distanceFromStart)")
                }
            }
        }
        
        // Force initial distance fetch
        HealthKitManager.shared.fetchTotalDistance()
        focusMapOnCurrentRoute()
        saveState()
        saveProgress()
    }
    
    func focusMapOnCurrentRoute() {
        guard let route = currentRoute else { return }
        
        // Set a closer zoom level when actively tracking
        let span = MKCoordinateSpan(
            latitudeDelta: isActivelyTracking ? 0.05 : 0.2,
            longitudeDelta: isActivelyTracking ? 0.05 : 0.2
        )
        
        let region = MKCoordinateRegion(
            center: route.startCoordinate,
            span: span
        )
        
        DispatchQueue.main.async {
            self.currentMapRegion = region
            print("🗺️ Updating currentMapRegion to: \(region)")
        }
    }
    
    func isRouteAvailable(_ route: VirtualRoute) -> Bool {
        // First route is always available
        if completedRoutes.isEmpty {
            return route == availableRoutes.first
        }
        
        // Find the index of the last completed route
        guard let lastCompletedRoute = completedRoutes.last,
              let lastCompletedIndex = availableRoutes.firstIndex(where: { $0.id == lastCompletedRoute.routeId }),
              let newRouteIndex = availableRoutes.firstIndex(where: { $0.id == route.id })
        else {
            return false
        }
        
        // Only allow selecting the next route in sequence
        return newRouteIndex == lastCompletedIndex + 1
    }
    
    private func loadRoutes() {
        Task {
            let routes = await RouteFactory.initializeRoutes()
            await MainActor.run {
                self.availableRoutes = routes
            }
        }
    }
    
    // MARK: - Progress Polyline Management
    func updateProgressPolyline() {
        guard let route = currentRoute else {
            progressPolyline = []
            return
        }
        
        var coordinates: [CLLocationCoordinate2D] = []
        var accumulatedDistance: Double = 0
        let targetDistance = HealthKitManager.shared.totalDistance
        
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
    func updateProgress(withDistance distance: Double, source: String = "unknown") {
        guard let progress = currentProgress,
              let route = currentRoute else {
            return
        }
        print("📊 Updating progress - Distance: \(distance), Source: \(source)")
        var updatedProgress = progress
        let cappedDistance = min(distance, route.totalDistance)
        
        let todayString = DateFormatter().string(from: Date())
        updatedProgress.updateDailyProgress(distance: distance, for: todayString)
        updatedProgress.updateCompletedDistance(distance)
        
        // Update current position
        if let newPosition = route.coordinate(at: cappedDistance) {
            currentRouteCoordinate = newPosition
        }
        
        // Store the current progress before checking new milestones
        currentProgress = updatedProgress
        checkMilestones(for: updatedProgress, at: HealthKitManager.shared.totalDistance)
        saveProgress()
        updateProgressPolyline()
    }
    
    
    
    func checkMilestones(for progress: RouteProgress, at distance: Double) {
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
        return isCompleted
    }
    
    // MARK: - Route Completion
    func handleRouteCompletion(_ progress: RouteProgress) {
        guard progress.isCompleted else { return }
        
        let routeId = progress.routeId
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !self.completedRoutes.contains(where: { $0.routeId == routeId }) {
                self.completedRoutes.append(progress)
                self.healthDataStore.updateRouteProgress(progress)
            }
            
            self.isActivelyTracking = false
            self.progressPolyline = []
            self.currentRouteCoordinate = nil
            self.recentlyUnlockedMilestone = nil
            self.currentProgress = nil
            self.currentRoute = nil
            self.showingRouteSelection = true
            
            print("🏁 Route completed and all states reset")
        }
    }
    
    // MARK: - Utility Functions
    
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
    
    func isRouteCompleted(_ routeId: UUID) -> Bool {
        completedRoutes.contains { $0.routeId == routeId }
    }
}
