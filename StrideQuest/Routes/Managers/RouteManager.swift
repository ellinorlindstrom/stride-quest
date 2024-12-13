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
        
        // Load any saved custom routes first
        loadSavedRoutes()
        
        // Initialize predefined routes
        var routes = initializeRoutes()
        
        // Process each route to ensure proper segments
        routes = routes.map { route in
            // Create segments between consecutive waypoints
            var routeSegments: [RouteSegment] = []
            
            if route.waypoints.count >= 2 {
                for i in 0..<(route.waypoints.count - 1) {
                    let start = route.waypoints[i]
                    let end = route.waypoints[i + 1]
                    
                    // Create a direct segment between waypoints
                    let segment = RouteSegment(coordinates: [start, end])
                    routeSegments.append(segment)
                }
            }
            
            // Calculate total distance based on segments
            let totalDistance = calculateTotalSegmentDistance(segments: routeSegments)
            
            return VirtualRoute(
                id: route.id,
                name: route.name,
                description: route.description,
                totalDistance: totalDistance,
                milestones: route.milestones,
                imageName: route.imageName,
                region: route.region,
                startCoordinate: route.waypoints.first ?? CLLocationCoordinate2D(),
                waypoints: route.waypoints,
                segments: routeSegments
            )
        }
        
        self.availableRoutes = routes
        loadProgress()
        loadCompletedRoutes()
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
        currentMapRegion = MKCoordinateRegion(
            center: selectedRoute.startCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        HealthKitManager.shared.markRouteStart()
        activeRouteIds.insert(selectedRoute.id)
        updateProgress(withDistance: currentProgress?.completedDistance ?? 0, source: "initial")
        saveProgress()
    }
    
    func pauseTracking() {
        if let selectedRoute = selectedRoute {
            activeRouteIds.remove(selectedRoute.id)
        }
        saveProgress()
    }
    
    func stopRoute() {
        if let selectedRoute = selectedRoute {
            activeRouteIds.remove(selectedRoute.id)
        }
        selectedRoute = nil
        saveProgress()
    }
    
    func updateProgress(withDistance distance: Double, isManual: Bool = false, source: String = "unknown") {
        guard var progress = currentProgress,
              let route = progress.currentRoute,
              activeRouteIds.contains(route.id) else {
            return
        }
        
        print("📍 RouteManager - Receiving update from \(source)")
        print("- Distance: \(distance) km")
        
        let todayString = DateFormatter().string(from: Date())
        progress.updateDailyProgress(distance: distance, for: todayString)
        progress.updateCompletedDistance(distance, isManual: isManual)
        
        // Update current position on the route
        if let newPosition = route.coordinate(at: distance * 1000) { // Convert km to meters
            currentRouteCoordinate = newPosition
        }
        
        // Check for new milestones
        for milestone in route.milestones.sorted(by: { $0.distanceFromStart < $1.distanceFromStart }) {
            let milestoneDistanceKm = milestone.distanceFromStart / 1000
            if distance >= milestoneDistanceKm && !progress.completedMilestones.contains(milestone.id) {
                progress.addCompletedMilestone(milestone.id)
                recentlyUnlockedMilestone = milestone
                milestoneCompletedPublisher.send(milestone)
            }
        }
        
        if distance >= (route.totalDistance / 1000) && !progress.isCompleted {
            progress.markCompleted()
        }
        
        currentProgress = progress
        saveProgress()
    }
    
    func isMilestoneCompleted(_ milestone: RouteMilestone) -> Bool {
        guard let progress = currentProgress else {
            print("❌ No current progress")
            return false
        }
        return progress.completedMilestones.contains(milestone.id)
    }
    
    func resetProgress() {
        if let progress = currentProgress {
            let context = healthDataStore.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", progress.id as CVarArg)
            
            do {
                if let entity = try context.fetch(fetchRequest).first {
                    context.delete(entity)
                    try context.save()
                }
            } catch {
                print("Failed to reset progress: \(error)")
            }
        }
        currentProgress = nil
    }

    func addCustomRoute(_ route: VirtualRoute) {
        let adjustedRoute = validateAndAdjustRoute(route)
        availableRoutes.append(adjustedRoute)
        saveRoutes()
    }
    
    func saveCustomRoute(_ customRoute: VirtualRoute) {
        addCustomRoute(customRoute)
        if let route = getRoute(by: customRoute.id) {
            selectRoute(route)
            beginRouteTracking()
        }
    }
    
    func getRoute(by id: UUID) -> VirtualRoute? {
        availableRoutes.first { route in route.id == id }
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
                totalDistance += startLocation.distance(from: endLocation)
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
    
    private func loadSavedRoutes() {
        guard let routeData = userDefaults.data(forKey: routesKey) else {
            return
        }
        
        do {
            let savedRoutes = try JSONDecoder().decode([VirtualRoute].self, from: routeData)
            availableRoutes.append(contentsOf: savedRoutes)
        } catch {
            print("Error loading saved routes: \(error)")
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
    
    private func loadCompletedRoutes() {
        let fetchedRoutes = healthDataStore.fetchAllRouteProgress()
        completedRoutes = fetchedRoutes
    }

    // MARK: - Computed Properties
    var availableUncompletedRoutes: [VirtualRoute] {
        let completedRouteIds = Set(completedRoutes.map { $0.routeId })
        return availableRoutes.filter { !completedRouteIds.contains($0.id) }
    }
}
