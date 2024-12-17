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
    
    private let healthDataStore = HealthDataStore.shared
    private let userDefaults = UserDefaults.standard
    private let routesKey = "savedRoutes"
    private let progressKey = "currentRouteProgress"
    private let completedRoutesKey = "completedRoutesKey"
    
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
    
    func handleRouteCompletion(_ progress: RouteProgress) {
        guard progress.isCompleted,
              let routeId = progress.currentRoute?.id else {
            return
        }
        // Perform UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Remove from active routes
            self.activeRouteIds.remove(routeId)
            // Add to completed routes if not already there
            let alreadyCompleted = self.completedRoutes.contains(where: { $0.routeId == routeId })
            if !alreadyCompleted {
                self.completedRoutes.append(progress)
                
                // Notify observers of the change
                self.objectWillChange.send()
                // Save on background thread
                Task {
                    await MainActor.run {
                        self.healthDataStore.updateRouteProgress(progress)
                        self.loadCompletedRoutes()
                    }
                }
            }
            
            // Clear current progress after adding to completed routes
            if self.currentProgress?.routeId == routeId {
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
            return
        }
        
        // Then check if we can get the route
        guard let route = currentProgressCheck.currentRoute else {
            return
        }
        
        // Finally check if the route is active
        guard activeRouteIds.contains(route.id) else {
            return
        }
        
        var progress = currentProgressCheck
        let cappedDistance = min(distance, route.totalDistance)
        
        let todayString = DateFormatter().string(from: Date())
        progress.updateDailyProgress(distance: distance, for: todayString)
        progress.updateCompletedDistance(distance, isManual: isManual)
        
        // Update current position on the route
        if let newPosition = route.coordinate(at: cappedDistance) {
            currentRouteCoordinate = newPosition
        }
        
        // Check for new milestones
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

        
        // Handle both newly completed routes and routes that were marked completed but not processed
        if isAtOrPastEnd {
            
            if !progress.isCompleted {
                progress.markCompleted()
            }
            
            // Check if this route is already in completedRoutes
            let isInCompletedRoutes = completedRoutes.contains(where: { $0.routeId == route.id })
            
            if !isInCompletedRoutes {
                currentProgress = progress
                handleRouteCompletion(progress)
                return
            } else {
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
    
    private func saveProgress() {
        guard let progress = currentProgress else { return }
        healthDataStore.updateRouteProgress(progress)
    }
    
    private func saveCompletedRoutes() {
        completedRoutes.forEach { route in
            healthDataStore.updateRouteProgress(route)
        }
    }
    
    func cleanupCompletedRoutes() {
        let validRouteIds = [RouteConstants.camino, RouteConstants.norwegianFjords, RouteConstants.bostonFreedom, RouteConstants.vancouverSeawall, RouteConstants.kyotoPhilosophersPath, RouteConstants.seoulCityWall, RouteConstants.bondiToBronte, RouteConstants.tableMount]
            
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
