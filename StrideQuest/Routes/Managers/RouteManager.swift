import Foundation
import CoreLocation
import MapKit

class RouteManager: ObservableObject {
    static let shared = RouteManager()
    
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
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "currentRouteProgress"
    private let completedRoutesKey = "completedRoutesKey"
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var cumulativeDistances: [Double] = []
    
    init() {
        self.availableRoutes = []
        self.availableRoutes = initializeRoutes()
        loadProgress()
        loadCompletedRoutes()
    }
    
    func startRoute(_ route: VirtualRoute) {
        let currentDistance = HealthKitManager.shared.totalDistance / 1000
        
        let progress = RouteProgress(
            id: UUID(),
            routeId: route.id,
            startDate: Date(),
            completedDistance: currentDistance,
            lastUpdated: Date(),
            completedMilestones: [],
            totalDistance: route.totalDistance,
            dailyProgress: [
                                RouteProgress.DailyProgress(
                                    date: Date(),
                                    distance: currentDistance
                                )
                            ],
            isCompleted: false
        )
        
        currentProgress = progress
        routeCoordinates = route.coordinates
        calculateCumulativeDistances()
        updateProgress(withDistance: currentDistance)
        
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
    
    func updateProgress(withDistance distance: Double, isManual: Bool = false) {
        guard var progress = currentProgress,
              let route = progress.currentRoute else {
            return
        }
        progress.completedDistance = isManual ? distance : max(distance, progress.completedDistance)
        progress.completedDistance = distance
        let routeTotalKm = route.totalDistance / 1000
        let percentComplete = distance / routeTotalKm
        
        // Update interpolated position
        if percentComplete > 0 && percentComplete < 1 {
            let targetDistance = distance * 1000 // Convert to meters
            
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
        
        // Check for new milestones
        for milestone in route.milestones {
            let milestoneDistanceKm = milestone.distanceFromStart / 1000
            if !progress.completedMilestones.contains(milestone.id) &&
                distance >= milestoneDistanceKm {
                progress.completedMilestones.insert(milestone.id)
                recentlyUnlockedMilestone = milestone
            }
        }
        
        progress.lastUpdated = Date()
        
        if distance >= routeTotalKm {
                    progress.isCompleted = true
                    progress.completionDate = Date()
                    completedRoutes.append(progress)
                    currentProgress = nil  // Reset current progress
                }
                
        
        currentProgress = progress
        saveProgress()
    }
    
    private func saveCompletedRoutes() {
           if let encoded = try? JSONEncoder().encode(completedRoutes) {
               userDefaults.set(encoded, forKey: completedRoutesKey)
           }
       }
    private func loadCompletedRoutes() {
            if let savedRoutes = userDefaults.data(forKey: completedRoutesKey),
               let decodedRoutes = try? JSONDecoder().decode([RouteProgress].self, from: savedRoutes) {
                completedRoutes = decodedRoutes
            }
        }
    
    var availableUncompletedRoutes: [VirtualRoute] {
        let completedRouteIds = Set(completedRoutes.map { $0.routeId })
        return availableRoutes.filter { !completedRouteIds.contains($0.id) }
    }
   
   func getRoute(by id: UUID) -> VirtualRoute? {
       availableRoutes.first { route in route.id == id }
   }
   
   private func saveProgress() {
       if let encoded = try? JSONEncoder().encode(currentProgress) {
           userDefaults.set(encoded, forKey: progressKey)
       }
   }
   
   private func loadProgress() {
       if let savedProgress = userDefaults.data(forKey: progressKey),
          let decodedProgress = try? JSONDecoder().decode(RouteProgress.self, from: savedProgress) {
           currentProgress = decodedProgress
       }
   }
   
   func resetProgress() {
       currentProgress = nil
       userDefaults.removeObject(forKey: progressKey)
   }
}


