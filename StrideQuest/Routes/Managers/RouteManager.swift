import Foundation
import CoreLocation
import MapKit
import CoreData
import Combine

class RouteManager: ObservableObject {
    let milestoneCompletedPublisher = PassthroughSubject<RouteMilestone, Never>()
    static let shared = RouteManager()
    @Published private(set) var isActivelyTracking: Bool = false
    @Published private(set) var selectedRoute: VirtualRoute?
    @Published var currentRouteCoordinate: CLLocationCoordinate2D?
    @Published private(set) var availableRoutes: [VirtualRoute]
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
    
    private let healthDataStore = HealthDataStore.shared
    private let progressKey = "currentRouteProgress"
    private let completedRoutesKey = "completedRoutesKey"
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var cumulativeDistances: [Double] = []

    
    init() {
        self.availableRoutes = []
        var routes = initializeRoutes()
        
        // Adjust each route's coordinates to match its total distance
        routes = routes.map { route in
            let trimmedCoordinates = trimCoordinatesToDistance(
                coordinates: route.coordinates,
                targetDistance: route.totalDistance
            )
            
            return VirtualRoute(
                id: route.id,
                name: route.name,
                description: route.description,
                totalDistance: route.totalDistance,
                milestones: route.milestones,
                imageName: route.imageName,
                region: route.region,
                startCoordinate: route.startCoordinate,
                coordinates: trimmedCoordinates
            )
        }
        
        self.availableRoutes = routes
        loadProgress()
        loadCompletedRoutes()
    }
    
    func selectRoute(_ route: VirtualRoute) {
            selectedRoute = route
        }
    
    func beginRouteTracking() {
            guard let selectedRoute = selectedRoute else { return }
                    
            let progress = RouteProgress(
                id: UUID(),
                routeId: selectedRoute.id,
                startDate: Date(),
                completedDistance: 0,
                lastUpdated: Date(),
                completedMilestones: Set<UUID>(),
                totalDistance: selectedRoute.totalDistance,
                dailyProgress: [
                    RouteProgress.DailyProgress(
                        date: Date(),
                        distance: 0
                    )
                ],
                isCompleted: false
            )
            
            currentProgress = progress
            routeCoordinates = selectedRoute.coordinates
            calculateCumulativeDistances()
            currentRouteCoordinate = selectedRoute.coordinates.first
            currentMapRegion = MKCoordinateRegion(
                center: selectedRoute.startCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            HealthKitManager.shared.markRouteStart()
            isActivelyTracking = true
            updateProgress(withDistance: 0, source: "initial")
            saveProgress()
        }
    

    func pauseTracking() {
        isActivelyTracking = false
        saveProgress()
    }

    func stopRoute() {
        isActivelyTracking = false
        selectedRoute = nil
        saveProgress()
    }
    
    private func calculateCumulativeDistances() {
        cumulativeDistances = [0]
        var totalDistance: Double = 0
        
        for i in 1..<routeCoordinates.count {
            let previous = routeCoordinates[i-1]
            let current = routeCoordinates[i]
            let distance = calculateDistance(from: previous, to: current)
            totalDistance += distance
            cumulativeDistances.append(totalDistance)
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    private func calculateActualDistance(coordinates: [CLLocationCoordinate2D]) -> Double {
        var totalDistance: Double = 0
        for i in 1..<coordinates.count {
            let prev = coordinates[i-1]
            let curr = coordinates[i]
            let from = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let to = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            totalDistance += from.distance(from: to)
        }
        return totalDistance
    }

    private func trimCoordinatesToDistance(coordinates: [CLLocationCoordinate2D], targetDistance: Double) -> [CLLocationCoordinate2D] {
        var trimmedCoordinates: [CLLocationCoordinate2D] = [coordinates[0]]
        var currentDistance: Double = 0
        
        for i in 1..<coordinates.count {
            let prev = coordinates[i-1]
            let curr = coordinates[i]
            let from = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let to = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            let segmentDistance = from.distance(from: to)
            
            if currentDistance + segmentDistance > targetDistance {
                // Interpolate final point
                let remainingDistance = targetDistance - currentDistance
                let fraction = remainingDistance / segmentDistance
                let newLat = prev.latitude + (curr.latitude - prev.latitude) * fraction
                let newLon = prev.longitude + (curr.longitude - prev.longitude) * fraction
                trimmedCoordinates.append(CLLocationCoordinate2D(latitude: newLat, longitude: newLon))
                break
            }
            
            currentDistance += segmentDistance
            trimmedCoordinates.append(curr)
        }
        
        return trimmedCoordinates
    }
    
    func updateProgress(withDistance distance: Double, isManual: Bool = false, source: String = "unknown") {
        guard isActivelyTracking,
                 var progress = currentProgress,
                 let route = progress.currentRoute else {
               return
           }
        print("📍 RouteManager - Receiving update from \(source)")
        print("- Distance: \(distance) km")
        print("- Current completed milestones count: \(progress.completedMilestones.count)")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastProgress = progress.dailyProgress.last,
               calendar.startOfDay(for: lastProgress.date) == today {
                // Update today's progress
                var updatedDailyProgress = progress.dailyProgress
                updatedDailyProgress[updatedDailyProgress.count - 1].distance = distance
                progress.dailyProgress = updatedDailyProgress
            } else {
                // Add new day's progress
                progress.dailyProgress.append(
                    RouteProgress.DailyProgress(
                        date: Date(),
                        distance: distance
                    )
                )
            }
        
        let totalCompleted = progress.dailyProgress.reduce(0) { $0 + $1.distance }
           progress.completedDistance = isManual ? distance : max(distance, progress.completedDistance)
           
        //progress.completedDistance = distance
        let routeTotalKm = route.totalDistance / 1000
        let percentComplete = distance / routeTotalKm
        
       
        // Update position marker
        if percentComplete > 0 && percentComplete < 1 {
            let targetDistance = distance * 1000 // Convert to meters
            updatePositionMarker(targetDistance: targetDistance)
            
        }
        
        // Check for new milestones
        for milestone in route.milestones.sorted(by: { $0.distanceFromStart < $1.distanceFromStart }) {
               let milestoneDistanceKm = milestone.distanceFromStart / 1000
               if totalCompleted >= milestoneDistanceKm && !progress.completedMilestones.contains(milestone.id) {
                   progress.completedMilestones.insert(milestone.id)
                   recentlyUnlockedMilestone = milestone
                   print("✅ Milestone unlocked: \(milestone.name) at \(milestoneDistanceKm) km")
                   milestoneCompletedPublisher.send(milestone)

                   // Add notification or celebration effect here
               }
           }
        
        currentProgress = progress
        saveProgress()

    }
    
    func isMilestoneCompleted(_ milestone: RouteMilestone) -> Bool {
        guard let progress = currentProgress else {
            print("❌ No current progress")
            return false
        }
        let isCompleted = progress.completedMilestones.contains(milestone.id)
        print("🏁 Checking milestone: \(milestone.name)")
        print("- Distance from start: \(milestone.distanceFromStart/1000) km")
        print("- Current distance: \(progress.completedDistance) km")
        print("- Is in completed set: \(isCompleted)")
        return isCompleted
    }
    
    private func updatePositionMarker(targetDistance: Double) {
            var lastPointIndex = 0
            for (index, cumDistance) in cumulativeDistances.enumerated() {
                if cumDistance > targetDistance {
                    lastPointIndex = index
                    break
                }
            }
            
            if lastPointIndex > 0 {
                let previousDistance = cumulativeDistances[lastPointIndex - 1]
                let nextDistance = cumulativeDistances[lastPointIndex]
                let fraction = (targetDistance - previousDistance) / (nextDistance - previousDistance)
                
                let start = routeCoordinates[lastPointIndex - 1]
                let end = routeCoordinates[lastPointIndex]
                
                let interpolatedLat = start.latitude + (end.latitude - start.latitude) * fraction
                let interpolatedLon = start.longitude + (end.longitude - start.longitude) * fraction
                
                currentRouteCoordinate = CLLocationCoordinate2D(latitude: interpolatedLat, longitude: interpolatedLon)
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
    
    var availableUncompletedRoutes: [VirtualRoute] {
        let completedRouteIds = Set(completedRoutes.map { $0.routeId })
        return availableRoutes.filter { !completedRouteIds.contains($0.id) }
    }
    
    func getRoute(by id: UUID) -> VirtualRoute? {
        availableRoutes.first { route in route.id == id }
    }
    
    private func saveProgress() {
        guard let progress = currentProgress else { return }
        healthDataStore.updateRouteProgress(progress)
    }
    
    private func loadProgress() {
        // Fetch the most recent incomplete route progress
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
                    isCompleted: false
                )
            }
        } catch {
            print("Failed to load progress: \(error)")
        }
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
    
}
