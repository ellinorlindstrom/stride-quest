import Foundation
import CoreLocation

enum RouteConstants {
    private static func createUUID(from string: String) -> UUID {
        if let uuid = UUID(uuidString: string) {
            return uuid
        } else {
            fatalError("Invalid UUID string: \(string)")
            // Or alternatively, return a default UUID:
            // return UUID()
        }
    }
    
    // Europe
    static let camino = createUUID(from: "E5674600-8577-4DED-A7C7-24D836AC4842")
    static let norwegianFjords = createUUID(from: "A7890123-4567-89AB-CDEF-012345678901")
    
    // North America
    static let bostonFreedom = createUUID(from: "B1234567-89AB-CDEF-0123-456789ABCDEF")
    static let vancouverSeawall = createUUID(from: "C2345678-9ABC-DEF0-1234-56789ABCDEF0")
    
    // Asia
    static let kyotoPhilosophersPath = createUUID(from: "D3456789-ABCD-EF01-2345-6789ABCDEF01")
    static let seoulCityWall = createUUID(from: "E4567890-BCDE-F012-3456-789ABCDEF012")
    
    // Australia
    static let bondiToBronte = createUUID(from: "F5678901-CDEF-0123-4567-89ABCDEF0123")
    
    // Africa
    static let tableMount = createUUID(from: "66789012-DEF0-1234-5678-9ABCDEF01234")
}

extension RouteManager {
    func initializeRoutes() async -> [VirtualRoute] {
        async let routes = createAllRoutes()
        return (try? await routes) ?? []
    }
    
    private func createAllRoutes() async throws -> [VirtualRoute] {
        // Create all routes concurrently
        async let route1 = createCaminoRoute()
        async let route2 = createNorwegianFjordsRoute()
        async let route3 = createBostonFreedomRoute()
        async let route4 = createVancouverSeawallRoute()
        async let route5 = createKyotoPhilosophersRoute()
        async let route6 = createSeoulCityWallRoute()
        async let route7 = createBondiToBronteRoute()
        async let route8 = createTableMountainRoute()
        
        let routes = try await [
            route1, route2, route3, route4,
            route5, route6, route7, route8
        ]
        
        return try await updateRouteDistances(routes)
    }
    
    private func updateRouteDistances(_ routes: [VirtualRoute]) async throws -> [VirtualRoute] {
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
    
    // Create routes with segments
    private func createCaminoRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.camino,
            name: "Camino de Santiago",
            description: "Follow the historic pilgrimage route through Spain",
            totalDistance: 825.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.camino,
                    name: "Saint-Jean-Pied-de-Port",
                    description: "A picturesque French village nestled in the Pyrenees, marking the traditional starting point of the French Way. Medieval cobblestone streets and ancient city walls set the stage for your pilgrimage.",
                    distanceFromStart: 0,
                    imageName: "saint-jean"
                ),
                RouteMilestone(
                    routeId: RouteConstants.camino,
                    name: "Pamplona",
                    description: "Famous for the Running of the Bulls festival, this vibrant city offers medieval architecture, pintxos bars, and the stunning Gothic Cathedral of Santa María la Real. A major milestone on the Camino Frances.",
                    distanceFromStart: 74.800,
                    imageName: "pamplona"
                ),
                RouteMilestone(
                    routeId: RouteConstants.camino,
                    name: "Burgos Cathedral",
                    description: "A masterpiece of Spanish Gothic architecture and UNESCO World Heritage site. The cathedral's intricate spires and ornate facade showcase centuries of artistic excellence and religious devotion.",
                    distanceFromStart: 282.000,
                    imageName: "burgos"
                ),
                RouteMilestone(
                    routeId: RouteConstants.camino,
                    name: "Santiago de Compostela",
                    description: "The magnificent endpoint of the Camino, where pilgrims have journeyed for over a millennium. The cathedral houses the tomb of St. James and its giant thurible, the Botafumeiro, swings dramatically during pilgrim masses.",
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
    }
    
    // Norway - Moderate Hike
    private func createNorwegianFjordsRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.norwegianFjords,
            name: "Trolltunga Trail",
            description: "Spectacular hike to one of Norway's most dramatic viewpoints",
            totalDistance: 27.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.norwegianFjords,
                    name: "Skjeggedal",
                    description: "The gateway to Trolltunga, this valley base camp offers stunning views of Norwegian fjords and waterfalls. Starting point facilities prepare hikers for the challenging ascent ahead.",
                    distanceFromStart: 0,
                    imageName: "skjeggedal"
                ),
                RouteMilestone(
                    routeId: RouteConstants.norwegianFjords,
                    name: "Trolltunga",
                    description: "A spectacular rock formation jutting out 700 meters above Lake Ringedalsvatnet. This 'Troll's Tongue' offers one of Norway's most dramatic photo opportunities and panoramic views of the fjords.",
                    distanceFromStart: 27.000,
                    imageName: "trolltunga-trail"
                )
            ],
            imageName: "trolltunga-trail",
            region: "Norway",
            waypoints: [
                CLLocationCoordinate2D(latitude: 60.1252, longitude: 6.7458), // Skjeggedal
                CLLocationCoordinate2D(latitude: 60.1241, longitude: 6.7400), // Mid point
                CLLocationCoordinate2D(latitude: 60.1244, longitude: 6.7495)  // Trolltunga
            ]
        )
    }
    
    // USA - Historical City Walk
    private func createBostonFreedomRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.bostonFreedom,
            name: "Boston Freedom Trail",
            description: "Walk through history on Boston's iconic Freedom Trail",
            totalDistance: 4.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "Boston Common",
                    description: "America's oldest public park",
                    distanceFromStart: 0,
                    imageName: "boston-common"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "Paul Revere House",
                    description: "Historic home of American patriot",
                    distanceFromStart: 2.500,
                    imageName: "paul-revere"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "USS Constitution",
                    description: "Historic naval vessel",
                    distanceFromStart: 4.000,
                    imageName: "uss-constitution"
                )
            ],
            imageName: "freedom-trail",
            region: "USA",
            waypoints: [
                CLLocationCoordinate2D(latitude: 42.3551, longitude: -71.0657), // Boston Common
                CLLocationCoordinate2D(latitude: 42.3639, longitude: -71.0537), // Paul Revere House
                CLLocationCoordinate2D(latitude: 42.3724, longitude: -71.0567)  // USS Constitution
            ]
        )
    }
    
    // Canada - Urban Nature Walk
    private func createVancouverSeawallRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.vancouverSeawall,
            name: "Stanley Park Seawall",
            description: "Scenic waterfront path around Vancouver's Stanley Park",
            totalDistance: 10.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "Coal Harbour",
                    description: "Starting point with city views",
                    distanceFromStart: 0,
                    imageName: "coal-harbour"
                ),
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "Lions Gate Bridge",
                    description: "Iconic suspension bridge",
                    distanceFromStart: 5.000,
                    imageName: "lions-gate"
                ),
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "English Bay",
                    description: "Beautiful beach area",
                    distanceFromStart: 10.000,
                    imageName: "english-bay"
                )
            ],
            imageName: "stanley-park",
            region: "Canada",
            waypoints: [
                CLLocationCoordinate2D(latitude: 49.2899, longitude: -123.1219), // Coal Harbour
                CLLocationCoordinate2D(latitude: 49.3136, longitude: -123.1483), // Lions Gate
                CLLocationCoordinate2D(latitude: 49.2866, longitude: -123.1442)  // English Bay
            ]
        )
    }
    
    // Japan - Cultural Walk
    private func createKyotoPhilosophersRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.kyotoPhilosophersPath,
            name: "Philosopher's Path",
            description: "Peaceful stone path through historic Kyoto",
            totalDistance: 2.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Ginkaku-ji",
                    description: "The Silver Pavilion, a Zen temple of extraordinary beauty. Its minimalist design, moss garden, and sand sculptures exemplify Japanese aesthetics and the pursuit of perfection in simplicity.",
                    distanceFromStart: 0,
                    imageName: "ginkakuji"
                ),
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Nanzen-ji",
                    description: "One of Japan's most important Zen temples, featuring magnificent gates, a surprising aqueduct, and tranquil rock gardens. The temple grounds offer a perfect blend of architecture and nature.",
                    distanceFromStart: 2.000,
                    imageName: "nanzenji"
                )
            ],
            imageName: "philosophers-path",
            region: "Japan",
            waypoints: [
                CLLocationCoordinate2D(latitude: 35.0271, longitude: 135.7944), // Ginkaku-ji
                CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7932)  // Nanzen-ji
            ]
        )
    }
    
    // South Korea - Urban Historical
    private func createSeoulCityWallRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.seoulCityWall,
            name: "Seoul City Wall Trail",
            description: "Historic fortress wall trail with city views",
            totalDistance: 18.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.seoulCityWall,
                    name: "Heunginjimun Gate",
                    description: "Also known as Dongdaemun, this majestic gate served as the major eastern entrance to Seoul during the Joseon Dynasty. Now it stands as a proud symbol of Korea's architectural heritage.",
                    distanceFromStart: 0,
                    imageName: "heunginjimun"
                ),
                RouteMilestone(
                    routeId: RouteConstants.seoulCityWall,
                    name: "Namsan Seoul Tower",
                    description: "Rising 236m above sea level, this iconic communication and observation tower offers 360-degree views of the sprawling metropolis. Famous for its love locks and rotating restaurant.",
                    distanceFromStart: 9.000,
                    imageName: "namsan"
                ),
                RouteMilestone(
                    routeId: RouteConstants.seoulCityWall,
                    name: "Sukjeongmun Gate",
                    description: "The Great Northern Gate of Seoul's historical city wall, offering panoramic views of the city. This restored gate represents the northern guardian of Seoul's traditional boundaries.",
                    distanceFromStart: 18.000,
                    imageName: "sukjeongmun"
                )
            ],
            imageName: "seoul-wall",
            region: "South Korea",
            waypoints: [
                CLLocationCoordinate2D(latitude: 37.5710, longitude: 127.0094), // Heunginjimun
                CLLocationCoordinate2D(latitude: 37.5512, longitude: 126.9882), // Namsan Tower
                CLLocationCoordinate2D(latitude: 37.5963, longitude: 126.9669)  // Sukjeongmun
            ]
        )
    }
    
    // Australia - Coastal Walk
    private func createBondiToBronteRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.bondiToBronte,
            name: "Bondi to Bronte Coastal Walk",
            description: "Scenic coastal walk past Sydney's famous beaches",
            totalDistance: 2.500,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.bondiToBronte,
                    name: "Bondi Beach",
                    description: "Australia's most famous beach, known for its golden sand, pristine waves, and vibrant atmosphere. A paradise for surfers, swimmers, and sunbathers, showcasing the ultimate Aussie beach lifestyle.",
                    distanceFromStart: 0,
                    imageName: "bondi"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bondiToBronte,
                    name: "Tamarama Beach",
                    description: "Nicknamed 'Glamarama' by locals, this small but picturesque beach offers dramatic cliffs, excellent surfing conditions, and a more intimate atmosphere than its famous neighbors.",
                    distanceFromStart: 1.200,
                    imageName: "tamarama"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bondiToBronte,
                    name: "Bronte Beach",
                    description: "A charming family-friendly beach featuring a historic ocean pool, excellent cafes, and a large grassy park perfect for picnics. Popular with both locals and visitors for its natural rock pool.",
                    distanceFromStart: 2.500,
                    imageName: "bondi-bronte"
                )
            ],
            imageName: "bondi-bronte",
            region: "Australia",
            waypoints: [
                CLLocationCoordinate2D(latitude: -33.8915, longitude: 151.2767), // Bondi
                CLLocationCoordinate2D(latitude: -33.9019, longitude: 151.2726), // Tamarama
                CLLocationCoordinate2D(latitude: -33.9037, longitude: 151.2684)  // Bronte
            ]
        )
    }
    
    // South Africa - Mountain Hike
    private func createTableMountainRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.tableMount,
            name: "Table Mountain Platteklip Gorge",
            description: "Direct route to the summit of Table Mountain",
            totalDistance: 3.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.tableMount,
                    name: "Platteklip Gorge Start",
                    description: "The main starting point for the most direct route to the summit. This historic trail has been used since the first recorded ascent of Table Mountain in 1503.",

                    distanceFromStart: 0,
                    imageName: "platteklip-start"
                ),
                RouteMilestone(
                    routeId: RouteConstants.tableMount,
                    name: "Table Mountain Summit",
                    description: "The iconic flat-topped peak offering breathtaking 360-degree views of Cape Town, the Atlantic Ocean, and neighboring peaks. Home to unique fynbos vegetation and elusive rock hyraxes.",
                    distanceFromStart: 3.000,
                    imageName: "table-summit"
                )
            ],
            imageName: "table-mountain",
            region: "South Africa",
            waypoints: [
                CLLocationCoordinate2D(latitude: -33.9566, longitude: 18.4041), // Start
                CLLocationCoordinate2D(latitude: -33.9575, longitude: 18.4049), // Mid-point
                CLLocationCoordinate2D(latitude: -33.9577, longitude: 18.4058)  // Summit
            ]
        )
    }
}


