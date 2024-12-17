import Foundation
import CoreLocation

enum RouteConstants {
    static let camino = UUID(uuidString: "E5674600-8577-4DED-A7C7-24D836AC4842")!
    static let incaTrail = UUID(uuidString: "18789900-8BE5-4EE2-8969-47019523AE88")!
}

extension RouteManager {
    func initializeRoutes() async -> [VirtualRoute] {
        
        let caminoId = RouteConstants.camino
        let incaTrailId = RouteConstants.incaTrail

        // Create routes with segments
        async let caminoRoute = createRouteWithSegments(
            id: caminoId,
            name: "Camino de Santiago",
            description: "Follow the historic pilgrimage route through Spain",
            totalDistance: 82.500,
            milestones: [
                RouteMilestone(
                    routeId: caminoId,
                    name: "Saint-Jean-Pied-de-Port",
                    description: "Historic starting point in France",
                    distanceFromStart: 0,
                    imageName: "saint-jean"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Pamplona",
                    description: "Historic city famous for the Running of the Bulls",
                    distanceFromStart: 74.800,
                    imageName: "pamplona"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Burgos Cathedral",
                    description: "UNESCO World Heritage Gothic cathedral",
                    distanceFromStart: 282.000,
                    imageName: "burgos"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Santiago de Compostela",
                    description: "Final destination of the Camino",
                    distanceFromStart: 825.000,
                    imageName: "santiago"
                )
            ],
            imageName: "camino-de-santiago",
            region: "Spain",
            waypoints: [
                CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358), // Saint-Jean-Pied-de-Port
                CLLocationCoordinate2D(latitude: 42.8188, longitude: -1.6444), // Pamplona
                CLLocationCoordinate2D(latitude: 42.3439, longitude: -3.6966), // Burgos
                CLLocationCoordinate2D(latitude: 42.8805, longitude: -8.5459)  // Santiago
            ]
        )
        
        async let incaRoute = createRouteWithSegments(
            id: incaTrailId,
            name: "Inca Trail to Machu Picchu",
            description: "Classic 4-day trek through the Andes Mountains to Machu Picchu",
            totalDistance: 43.000,
            milestones: [
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Km 82 (Piscacucho)",
                    description: "Starting point of the Inca Trail",
                    distanceFromStart: 0,
                    imageName: ""
                ),
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Dead Woman's Pass",
                    description: "Highest point of the trail (4,215m)",
                    distanceFromStart: 14.333,
                    imageName: "dead_womans_pass"
                ),
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Machu Picchu",
                    description: "The legendary Lost City of the Incas",
                    distanceFromStart: 43.000,
                    imageName: "machu_picchu"
                )
            ],
            imageName: "inca-trail",
            region: "Cusco Region, Peru",
            waypoints: [
                CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784), // Km 82
                CLLocationCoordinate2D(latitude: -13.3986, longitude: -72.0912), // Dead Woman's Pass
                CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5449)  // Machu Picchu
            ]
        )
        
        do {
            // Wait for both routes to be created
            let routes = try await [caminoRoute, incaRoute]
            
            // Update milestone distances based on actual route segments
            return routes.map { route in
                var updatedMilestones = route.milestones
                
                // Calculate cumulative distances for each waypoint
                var cumulativeDistance: Double = 0
                var waypointDistances: [Double] = [0]
                
                for i in 0..<(route.segments.count) {
                    cumulativeDistance += route.segments[i].distance
                    waypointDistances.append(cumulativeDistance)
                }
                
                // Update milestone distances based on nearest waypoint
                updatedMilestones = updatedMilestones.map { milestone in
                    var updatedMilestone = milestone
                    
                    // Find the closest waypoint distance to the milestone's original distance percentage
                    let originalPercentage = milestone.distanceFromStart / route.totalDistance
                    let targetDistance = originalPercentage * cumulativeDistance
                    
                    // Find the closest waypoint distance
                    let closestDistance = waypointDistances.min(by: { abs($0 - targetDistance) < abs($1 - targetDistance) }) ?? 0
                    
                    // Update the milestone's distance
                    updatedMilestone = RouteMilestone(
                        id: milestone.id,
                        routeId: milestone.routeId,
                        name: milestone.name,
                        description: milestone.description,
                        distanceFromStart: closestDistance,
                        imageName: milestone.imageName
                    )
                    
                    return updatedMilestone
                }
                
                // Create updated route with adjusted milestone distances
                return VirtualRoute(
                    id: route.id,
                    name: route.name,
                    description: route.description,
                    totalDistance: cumulativeDistance,
                    milestones: updatedMilestones,
                    imageName: route.imageName,
                    region: route.region,
                    startCoordinate: route.startCoordinate,
                    waypoints: route.waypoints,
                    segments: route.segments
                )
            }
        } catch {
            print("Error creating routes: \(error)")
            return []
        }
    }
    
    private func createRouteWithSegments(
        id: UUID,
        name: String,
        description: String,
        totalDistance: Double,
        milestones: [RouteMilestone],
        imageName: String,
        region: String,
        waypoints: [CLLocationCoordinate2D]
    ) async throws -> VirtualRoute {
        var segments: [RouteSegment] = []
        
        // Create walking segments between consecutive waypoints
        for i in 0..<(waypoints.count - 1) {
            do {
                let segment = try await RouteSegment.createWalkingSegment(
                    from: waypoints[i],
                    to: waypoints[i + 1]
                )
                segments.append(segment)
            } catch {
                print("Error creating segment between waypoints \(i) and \(i+1): \(error)")
                // Fallback to direct line segment if walking directions fail
                let fallbackSegment = RouteSegment(coordinates: [waypoints[i], waypoints[i + 1]])
                segments.append(fallbackSegment)
            }
        }
        
        // Calculate actual total distance based on segments
        let actualDistance = segments.reduce(0) { $0 + $1.distance }
        
        return VirtualRoute(
            id: id,
            name: name,
            description: description,
            totalDistance: actualDistance,
            milestones: milestones,
            imageName: imageName,
            region: region,
            startCoordinate: waypoints.first ?? CLLocationCoordinate2D(),
            waypoints: waypoints,
            segments: segments
        )
    }
    
}
