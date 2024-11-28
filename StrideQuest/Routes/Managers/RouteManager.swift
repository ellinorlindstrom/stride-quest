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

   @Published private(set) var recentlyUnlockedMilestone: RouteMilestone?
   @Published var currentMapRegion: MKCoordinateRegion?
   
   private let userDefaults = UserDefaults.standard
   private let progressKey = "currentRouteProgress"
   private var routeCoordinates: [CLLocationCoordinate2D] = []
   
   init() {
       self.availableRoutes = []
       self.availableRoutes = initializeRoutes()
       loadProgress()
   }
   
    func startRoute(_ route: VirtualRoute) {
        let currentDistance = HealthKitManager.shared.totalDistance / 1000 // Convert to km
        
        let progress = RouteProgress(
            routeId: route.id,
            startDate: Date(),
            completedDistance: currentDistance, // Start with current distance
            lastUpdated: Date(),
            completedMilestones: [],
            isCompleted: false
        )
                
        currentProgress = progress
        routeCoordinates = route.coordinates
        currentRouteCoordinate = route.startCoordinate
        currentMapRegion = MKCoordinateRegion(
            center: route.startCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        saveProgress()
    }
   
    func updateProgress(withDistance distance: Double) {
        guard var progress = currentProgress,
              let route = progress.currentRoute else {
            return
        }
        
        print("RouteManager updateProgress:")
        print("Incoming distance: \(distance) km")
        
        progress.completedDistance = distance
        
        let routeTotalKm = route.totalDistance / 1000
        let percentComplete = distance / routeTotalKm
        
        print("Route total: \(routeTotalKm) km")
        print("Calculated percentage: \((percentComplete * 100))%")
        
        // Update position along route
        let coordIndex = Int(floor(Double(routeCoordinates.count) * percentComplete))
        print("Coordinate index: \(coordIndex) of \(routeCoordinates.count)")
        
        if coordIndex < routeCoordinates.count {
            currentRouteCoordinate = routeCoordinates[coordIndex]
        }
        
        print("Debug Polyline:")
        print("Route total (km): \(routeTotalKm)")
        print("Completed distance (km): \(distance)")
        print("Percent complete: \((distance / routeTotalKm) * 100)%")  // Convert to percentage
        print("Coordinates count: \(route.coordinates.count)")
        
        // Calculate index based on percentage
        let lastIndex = Int(floor(Double(route.coordinates.count) * percentComplete))
        print("Last index: \(lastIndex)")
        
        // Update position along route
        if lastIndex < routeCoordinates.count {
            currentRouteCoordinate = routeCoordinates[lastIndex]
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
        
        // Check completion
        if distance >= routeTotalKm {
            progress.isCompleted = true
        }
        
        currentProgress = progress
        saveProgress()
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
