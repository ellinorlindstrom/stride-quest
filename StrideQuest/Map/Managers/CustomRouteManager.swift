import Foundation
import CoreLocation

struct Waypoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class CustomRouteManager: ObservableObject {
    @Published var waypoints: [Waypoint] = []
    @Published var totalDistance: Double = 0
    @Published var routeSegments: [RouteSegment] = []  // Add this to store segments
    static let shared = CustomRouteManager()
    
    func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
        if let lastWaypoint = waypoints.last {
            let distance = calculateDistance(from: lastWaypoint.coordinate, to: coordinate)
            totalDistance += distance
        }
        waypoints.append(Waypoint(coordinate: coordinate))
    }
    
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func saveRoute(name: String, description: String) -> VirtualRoute {
        let newRoute = VirtualRoute(
            id: UUID(),
            name: name,
            description: description,
            totalDistance: totalDistance,
            milestones: [], // Optional: Add milestones if needed
            imageName: "defaultImage",
            region: "Unknown Region",
            startCoordinate: waypoints.first?.coordinate ?? CLLocationCoordinate2D(),
            waypoints: waypoints.map { $0.coordinate },  // Changed from coordinates to waypoints
            segments: routeSegments  // Add the segments here
        )
        
        // Notify the RouteManager to add this new route
        RouteManager.shared.availableRoutes.append(newRoute)
        return newRoute
    }
    
    // Add function to update route segments
    func updateRouteSegments(_ segments: [RouteSegment]) {
        routeSegments = segments
    }
}
