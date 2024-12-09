import CoreLocation

class CustomRouteManager: ObservableObject {
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var totalDistance: Double = 0
    
    func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
        if let lastWaypoint = waypoints.last {
            let distance = calculateDistance(from: lastWaypoint, to: coordinate)
            totalDistance += distance
        }
        waypoints.append(coordinate)
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
            region: "Unknown Region", // Optional: Define the map region
            startCoordinate: waypoints.first ?? CLLocationCoordinate2D(),
            coordinates: waypoints
        )
        
        // Notify the RouteManager to add this new route
        RouteManager.shared.availableRoutes.append(newRoute)
        return newRoute
    }
}
