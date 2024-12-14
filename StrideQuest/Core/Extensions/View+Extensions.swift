import Foundation
import CoreLocation

extension RouteManager {
    func initializeRoutes() -> [VirtualRoute] {
        let caminoId = UUID()
        let incaTrailId = UUID()
        
        return [
            // Simplified Camino route with fewer waypoints and milestones
            VirtualRoute(
                id: caminoId,
                name: "Camino de Santiago",
                description: "Follow the historic pilgrimage route through Spain",
                totalDistance: 825000,
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
                        distanceFromStart: 74800,
                        imageName: "pamplona"
                    ),
                    RouteMilestone(
                        routeId: caminoId,
                        name: "Burgos Cathedral",
                        description: "UNESCO World Heritage Gothic cathedral",
                        distanceFromStart: 282000,
                        imageName: "burgos"
                    ),
                    RouteMilestone(
                        routeId: caminoId,
                        name: "Santiago de Compostela",
                        description: "Final destination of the Camino",
                        distanceFromStart: 825000,
                        imageName: "santiago"
                    )
                ],
                imageName: "camino-de-santiago",
                region: "Spain",
                startCoordinate: CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358),
                waypoints: [
                    CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358), // Saint-Jean-Pied-de-Port
                    CLLocationCoordinate2D(latitude: 42.8188, longitude: -1.6444), // Pamplona
                    CLLocationCoordinate2D(latitude: 42.3439, longitude: -3.6966), // Burgos
                    CLLocationCoordinate2D(latitude: 42.8805, longitude: -8.5459)  // Santiago
                ],
                segments: []
            ),
            
            // Simplified Inca Trail with key waypoints
            VirtualRoute(
                id: incaTrailId,
                name: "Inca Trail to Machu Picchu",
                description: "Classic 4-day trek through the Andes Mountains to Machu Picchu",
                totalDistance: 43000,
                milestones: [
                    RouteMilestone(
                        routeId: incaTrailId,
                        name: "Km 82 (Piscacucho)",
                        description: "Starting point of the Inca Trail",
                        distanceFromStart: 0,
                        imageName: "km82"
                    ),
                    RouteMilestone(
                        routeId: incaTrailId,
                        name: "Dead Woman's Pass",
                        description: "Highest point of the trail (4,215m)",
                        distanceFromStart: 14333,
                        imageName: "dead_womans_pass"
                    ),
                    RouteMilestone(
                        routeId: incaTrailId,
                        name: "Machu Picchu",
                        description: "The legendary Lost City of the Incas",
                        distanceFromStart: 43000,
                        imageName: "machu_picchu"
                    )
                ],
                imageName: "inca-trail",
                region: "Cusco Region, Peru",
                startCoordinate: CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784),
                waypoints: [
                    CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784), // Km 82
                    CLLocationCoordinate2D(latitude: -13.3986, longitude: -72.0912), // Dead Woman's Pass
                    CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5449)  // Machu Picchu
                ],
                segments: []
            )
        ]
    }
}
