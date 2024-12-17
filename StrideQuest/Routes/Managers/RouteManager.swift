import Foundation
import CoreLocation
import MapKit
import CoreData
import Combine

class RouteManager: ObservableObject {
    // MARK: - Published Properties
    let milestoneCompletedPublisher = PassthroughSubject<RouteMilestone, Never>()
    static let shared = RouteManager()
    @Published private(set) var activeRouteIds: Set<UUID> = []
    @Published private(set) var selectedRoute: VirtualRoute?
    @Published var currentRouteCoordinate: CLLocationCoordinate2D?
    @Published private(set) var currentProgress: RouteProgress? {
        didSet {
            print("RouteManager - Progress updated: \(currentProgress?.completedDistance ?? 0) km completed")
        }
    }
    @Published private(set) var completedRoutes: [RouteProgress] = [] {
        didSet {
            saveCompletedRoutes()
        }
    }
    @Published private(set) var recentlyUnlockedMilestone: RouteMilestone?
    @Published var currentMapRegion: MKCoordinateRegion?
    @Published var availableRoutes: [VirtualRoute] = []
    
    // MARK: - Private Properties
    private let healthDataStore = HealthDataStore.shared
    private let userDefaults = UserDefaults.standard
    private let routesKey = "savedRoutes"
    private let progressKey = "currentRouteProgress"
    private let completedRoutesKey = "completedRoutesKey"
    
    // MARK: - Initialization
    init() {
        self.availableRoutes = []
        
        loadCompletedRoutes()
        
        // Initialize predefined routes
        Task {
            let routes = await initializeRoutes()
            DispatchQueue.main.async {
                self.availableRoutes = routes
                self.cleanupCompletedRoutes()
                self.loadCompletedRoutes()
            }
        }
    }
    
    // MARK: - Public Methods
    func isTracking(route: VirtualRoute) -> Bool {
        return activeRouteIds.contains(route.id)
    }

    
    func selectRoute(_ route: VirtualRoute) {
        selectedRoute = route
    }
    
    func beginRouteTracking() {
        guard let selectedRoute = selectedRoute else { return }
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
    
    private func handleRouteCompletion(_ progress: RouteProgress) {
        print("🎬 Starting handleRouteCompletion")
        print("  - Progress ID: \(progress.id)")
        print("  - Is Completed Flag: \(progress.isCompleted)")
        
        guard progress.isCompleted,
              let routeId = progress.currentRoute?.id else {
            print("❌ Failed to complete route: missing data")
            print("  - Is Completed: \(progress.isCompleted)")
            print("  - Has Route ID: \(progress.currentRoute?.id != nil)")
            return
        }
        
        print("🏁 Processing completion for route: \(routeId)")
        
        // Perform UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📱 Executing main thread updates")
            
            // Remove from active routes
            self.activeRouteIds.remove(routeId)
            print("✅ Removed from active routes")
            
            // Add to completed routes if not already there
            let alreadyCompleted = self.completedRoutes.contains(where: { $0.routeId == routeId })
            print("  - Already in completed routes: \(alreadyCompleted)")
            
            if !alreadyCompleted {
                print("✅ Adding to completed routes")
                self.completedRoutes.append(progress)
                
                // Notify observers of the change
                self.objectWillChange.send()
                print("✅ Sent objectWillChange notification")
                
                // Save on background thread
                Task {
                    await MainActor.run {
                        self.healthDataStore.updateRouteProgress(progress)
                        print("✅ Saved to CoreData")
                        self.loadCompletedRoutes()
                        print("✅ Reloaded completed routes")
                    }
                }
            }
            
            // Clear current progress after adding to completed routes
            if self.currentProgress?.routeId == routeId {
                print("✅ Clearing current progress")
                self.currentProgress = nil
            }
        }
    }
    
    private func loadCompletedRoutes() {
        let fetchedRoutes = healthDataStore.fetchAllRouteProgress().filter { $0.isCompleted }
        DispatchQueue.main.async {
            self.completedRoutes = fetchedRoutes
            self.objectWillChange.send()
        }
    }
    
    
    func updateProgress(withDistance distance: Double, isManual: Bool = false, source: String = "unknown") {
        // First check if we have a current progress
        guard let currentProgressCheck = currentProgress else {
            print("❌ updateProgress - Early return: No current progress")
            return
        }
        
        // Then check if we can get the route
        guard let route = currentProgressCheck.currentRoute else {
            print("❌ updateProgress - Early return: No route found")
            return
        }
        
        // Finally check if the route is active
        guard activeRouteIds.contains(route.id) else {
            print("❌ updateProgress - Early return: Route is not active")
            print("  - Route ID: \(route.id)")
            print("  - Active IDs: \(activeRouteIds)")
            return
        }
        
        var progress = currentProgressCheck
        let cappedDistance = min(distance, route.totalDistance)
        
        let todayString = DateFormatter().string(from: Date())
        progress.updateDailyProgress(distance: cappedDistance, for: todayString)
        progress.updateCompletedDistance(cappedDistance, isManual: isManual)
        
        // Update current position on the route
        if let newPosition = route.coordinate(at: cappedDistance) {
            currentRouteCoordinate = newPosition
        }
        
        // Check for new milestones
        print("🚀 updateProgress - Current Distance: \(cappedDistance)")
        print("📏 Route total distance: \(route.totalDistance)")
        
        for milestone in route.milestones.sorted(by: { $0.distanceFromStart < $1.distanceFromStart }) {
            if cappedDistance >= milestone.distanceFromStart && !progress.completedMilestones.contains(milestone.id) {
                progress.addCompletedMilestone(milestone.id)
                recentlyUnlockedMilestone = milestone
                milestoneCompletedPublisher.send(milestone)
            }
        }
        
        // Check for route completion with a small epsilon for floating-point comparison
        let epsilon = 0.0001 // Small tolerance value
        let isAtOrPastEnd = (cappedDistance + epsilon) >= route.totalDistance
        
        print("🎯 Completion check:")
        print("  - Completed Distance: \(cappedDistance)")
        print("  - Total Distance: \(route.totalDistance)")
        print("  - Difference: \(route.totalDistance - cappedDistance)")
        print("  - Is Already Completed: \(progress.isCompleted)")
        print("  - Is At or Past End: \(isAtOrPastEnd)")
        
        // Handle both newly completed routes and routes that were marked completed but not processed
        if isAtOrPastEnd {
            print("🎯 Route at completion threshold")
            
            if !progress.isCompleted {
                print("📍 Marking route as completed")
                progress.markCompleted()
            }
            
            // Check if this route is already in completedRoutes
            let isInCompletedRoutes = completedRoutes.contains(where: { $0.routeId == route.id })
            print("📍 Route in completed routes: \(isInCompletedRoutes)")
            
            if !isInCompletedRoutes {
                print("📍 Processing completion")
                currentProgress = progress
                handleRouteCompletion(progress)
                print("✅ Route completion handled")
                return
            } else {
                print("📍 Route already processed as completed")
            }
        }
        
        currentProgress = progress
        saveProgress()
    }
    
    func isRouteCompleted(_ routeId: UUID) -> Bool {
        completedRoutes.contains { $0.routeId == routeId }
    }
    
    
    func isMilestoneCompleted(_ milestone: RouteMilestone) -> Bool {
        guard let progress = currentProgress else {
            print("❌ No current progress")
            return false
        }
        return progress.completedMilestones.contains(milestone.id)
    }
    
    
    func getRoute(by id: UUID) -> VirtualRoute? {
        availableRoutes.first { route in route.id == id }
    }
    
    func updateMapRegion(_ region: MKCoordinateRegion) {
        currentMapRegion = region
    }
    
    // MARK: - Private Methods
    private func calculateTotalSegmentDistance(segments: [RouteSegment]) -> Double {
        var totalDistance: Double = 0
        
        for segment in segments {
            let coordinates = segment.path
            for i in 0..<(coordinates.count - 1) {
                let start = coordinates[i]
                let end = coordinates[i + 1]
                let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
                let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
                totalDistance += startLocation.distance(from: endLocation) / 1000.0
            }
        }
        
        return totalDistance
    }
    
    private func validateAndAdjustRoute(_ route: VirtualRoute) -> VirtualRoute {
        let totalDistance = calculateTotalSegmentDistance(segments: route.segments)
        
        return VirtualRoute(
            id: route.id,
            name: route.name,
            description: route.description,
            totalDistance: totalDistance,
            milestones: route.milestones,
            imageName: route.imageName,
            region: route.region,
            startCoordinate: route.startCoordinate,
            waypoints: route.waypoints,
            segments: route.segments
        )
    }
    
    private func saveRoutes() {
        do {
            let routeData = try JSONEncoder().encode(availableRoutes)
            userDefaults.set(routeData, forKey: routesKey)
        } catch {
            print("Error saving routes: \(error)")
        }
    }
    
    private func saveProgress() {
        guard let progress = currentProgress else { return }
        healthDataStore.updateRouteProgress(progress)
    }
    
    private func loadProgress() {
        let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
        fetchRequest.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: false))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            if let entity = try healthDataStore.persistentContainer.viewContext.fetch(fetchRequest).first {
                currentProgress = RouteProgress(
                    id: entity.id ?? UUID(),
                    routeId: entity.routeId ?? UUID(),
                    startDate: entity.startDate ?? Date(),
                    completedDistance: entity.completedDistance,
                    lastUpdated: entity.lastUpdated ?? Date(),
                    completedMilestones: entity.getCompletedMilestones(),
                    totalDistance: entity.totalDistance,
                    dailyProgress: entity.getDailyProgress(),
                    isCompleted: entity.isCompleted,
                    completionDate: entity.completionDate
                )
            }
        } catch {
            print("Failed to load progress: \(error)")
        }
    }
    
    private func saveCompletedRoutes() {
        completedRoutes.forEach { route in
            healthDataStore.updateRouteProgress(route)
        }
    }
    
    func cleanupCompletedRoutes() {
            let validRouteIds = [RouteConstants.camino, RouteConstants.incaTrail]
            
            // Filter out completed routes that don't match our valid IDs
            completedRoutes = completedRoutes.filter { progress in
                validRouteIds.contains(progress.routeId)
            }
            
            // Save the cleaned up routes
            for progress in completedRoutes {
                healthDataStore.updateRouteProgress(progress)
            }
            
            // Optional: Delete invalid entries from CoreData
            let context = healthDataStore.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
            
            do {
                let entities = try context.fetch(fetchRequest)
                for entity in entities {
                    if let routeId = entity.routeId, !validRouteIds.contains(routeId) {
                        context.delete(entity)
                    }
                }
                try context.save()
            } catch {
                print("Error cleaning up CoreData: \(error)")
            }
        }

}
