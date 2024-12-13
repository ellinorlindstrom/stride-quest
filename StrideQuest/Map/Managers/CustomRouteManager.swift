import Foundation
import CoreLocation

struct Waypoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let order: Int
    
    init(coordinate: CLLocationCoordinate2D, order: Int) {
        self.coordinate = coordinate
        self.order = order
    }
}


class CustomRouteManager: ObservableObject {
    @Published var waypoints: [Waypoint] = []
    /// Total distance of the route in kilometers
    @Published var totalDistance: Double = 0
    @Published var routeSegments: [RouteSegment] = []
    static let shared = CustomRouteManager()
    
    func updateRouteSegments(_ segments: [RouteSegment]) {
            self.routeSegments = segments
        }
    
    func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
            let order = waypoints.count  // Use array count as order
            waypoints.append(Waypoint(coordinate: coordinate, order: order))
            if let lastWaypoint = waypoints.dropLast().last {
                let distance = calculateDistance(from: lastWaypoint.coordinate, to: coordinate)
                totalDistance += distance
            }
        }
    
    /// Calculates distance between two coordinates in kilometers
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 
    }
    
    func saveRoute(name: String, description: String, imageName: String? = nil) -> VirtualRoute {
            let newRoute = VirtualRoute(
                id: UUID(),
                name: name,
                description: description,
                totalDistance: totalDistance,
                milestones: createDefaultMilestones(), // Add this helper method
                imageName: imageName ?? .defaultRouteImage,
                region: "Custom Route",
                startCoordinate: waypoints.first?.coordinate ?? CLLocationCoordinate2D(),
                waypoints: waypoints.map { $0.coordinate },
                segments: routeSegments
            )
            
            // Instead of directly adding to RouteManager, use the new integration method
            RouteManager.shared.saveCustomRoute(newRoute)
            
            // Clear the current route data
            clearRoute()
            
            return newRoute
        }
    private func createDefaultMilestones() -> [RouteMilestone] {
            // Create milestones at 25%, 50%, and 75% of the route
            let distances = [0.25, 0.5, 0.75]
            return distances.map { percentage in
                RouteMilestone(
                    id: UUID(),
                    routeId: UUID(), 
                    name: "Milestone \(Int(percentage * 100))%",
                    description: "You've completed \(Int(percentage * 100))% of your custom route!",
                    distanceFromStart: totalDistance * percentage,
                    imageName: .defaultMilestoneImage
                )
            }
        }
        
        private func clearRoute() {
            waypoints = []
            totalDistance = 0
            routeSegments = []
        }
    }
