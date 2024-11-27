import Foundation
import CoreLocation
import MapKit

class RouteManager: ObservableObject {
   static let shared = RouteManager()
   
   @Published var currentRouteCoordinate: CLLocationCoordinate2D?
   @Published private(set) var availableRoutes: [VirtualRoute]
   @Published private(set) var currentProgress: RouteProgress?
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
       let progress = RouteProgress(
           routeId: route.id,
           startDate: Date(),
           completedDistance: 0,
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
             let route = progress.currentRoute else { return }
       
       progress.completedDistance = distance
       progress.lastUpdated = Date()
       
       // Update position along route
       let percentComplete = distance / route.totalDistance
       let coordIndex = Int(floor(Double(routeCoordinates.count) * percentComplete))
       
       if coordIndex < routeCoordinates.count {
           currentRouteCoordinate = routeCoordinates[coordIndex]
       }
       
       // Check for new milestones
       for milestone in route.milestones {
           if !progress.completedMilestones.contains(milestone.id) &&
               progress.completedDistance >= milestone.distanceFromStart {
               progress.completedMilestones.insert(milestone.id)
               recentlyUnlockedMilestone = milestone
           }
       }
       
       if progress.completedDistance >= route.totalDistance {
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
