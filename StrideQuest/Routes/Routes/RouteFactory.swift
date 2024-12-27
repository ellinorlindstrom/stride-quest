import Foundation
import CoreLocation
import SwiftUI

enum RouteConstants {
    private static func createUUID(from string: String) -> UUID {
        if let uuid = UUID(uuidString: string) {
            return uuid
        } else {
            fatalError("Invalid UUID string: \(string)")
        }
    }
    
    // Europe
    static let camino = createUUID(from: "E5674600-8577-4DED-A7C7-24D836AC4842")
    static let highCoast = createUUID(from: "A7890123-4567-89AB-CDEF-012345678901")
    
    // North America
    static let bostonFreedom = createUUID(from: "B1234567-89AB-CDEF-0123-456789ABCDEF")
    static let vancouverSeawall = createUUID(from: "C2345678-9ABC-DEF0-1234-56789ABCDEF0")
    
    // Asia
    static let greatWall = createUUID(from: "F1234567-89AB-CDEF-0123-456789ABCDEF")
    static let kyotoPhilosophersPath = createUUID(from: "D3456789-ABCD-EF01-2345-6789ABCDEF01")
    static let seoulCityWall = createUUID(from: "E4567890-BCDE-F012-3456-789ABCDEF012")
    
    // Australia
    static let bondiToBronte = createUUID(from: "F5678901-CDEF-0123-4567-89ABCDEF0123")
    
    // Africa
    static let tableMount = createUUID(from: "66789012-DEF0-1234-5678-9ABCDEF01234")
}

enum RouteFactory {
    static func initializeRoutes() async -> [VirtualRoute] {
        async let routes = createAllRoutes()
        return (try? await routes) ?? []
    }
    
    private static func createAllRoutes() async throws -> [VirtualRoute] {
        // Create all routes concurrently
        async let route1 = createBondiToBronteRoute()
        async let route2 = createTableMountainRoute()
        async let route3 = createHighCoastRoute()
        async let route4 = createKyotoPhilosophersRoute()
        async let route5 = createVancouverSeawallRoute()
        async let route6 = createCaminoRoute()
        async let route7 = createSeoulCityWallRoute()
        async let route8 = createBostonFreedomRoute()

        let routes = try await [
            route1, route2, route3, route4,
            route5, route6, route7, route8
        ]
        
        return try await updateRouteDistances(routes)
    }
    
    private static func updateRouteDistances(_ routes: [VirtualRoute]) async throws -> [VirtualRoute] {
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
    
    private static func createRouteWithSegments(
        id: UUID,
        name: String,
        description: String,
        totalDistance: Double,
        milestones: [RouteMilestone],
        imageName: String,
        region: String,
        waypoints: [CLLocationCoordinate2D]
    ) async throws -> VirtualRoute {
        // Validate input
        guard !waypoints.isEmpty else {
            throw RouteError.invalidCoordinate
        }
        
        var segments: [RouteSegment] = []
        var fallbackSegmentsUsed = false
        
        // Create walking segments between consecutive waypoints
        for i in 0..<(waypoints.count - 1) {
            let start = waypoints[i]
            let end = waypoints[i + 1]
            
            do {
                // Validate coordinates before attempting to create segment
                guard CLLocationCoordinate2DIsValid(start), CLLocationCoordinate2DIsValid(end) else {
                    print("⚠️ Invalid coordinates detected for waypoints \(i) and \(i+1)")
                    throw RouteError.invalidCoordinate
                }
                
                let segment = try await RouteUtils.createWalkingSegment(
                    from: start,
                    to: end
                )
                segments.append(segment)
                
            } catch RouteError.maxRetriesExceeded(let underlyingError) {
                print("🚨 Max retries exceeded for segment \(i) to \(i+1). Error: \(underlyingError?.localizedDescription ?? "Unknown")")
                fallbackSegmentsUsed = true
                let fallbackSegment = RouteSegment(coordinates: [start, end])
                segments.append(fallbackSegment)
                
            } catch RouteError.invalidCoordinate {
                print("🚨 Invalid coordinates for segment \(i) to \(i+1)")
                throw RouteError.invalidCoordinate
                
            } catch {
                print("🚨 Error creating segment \(i) to \(i+1): \(error.localizedDescription)")
                fallbackSegmentsUsed = true
                let fallbackSegment = RouteSegment(coordinates: [start, end])
                segments.append(fallbackSegment)
            }
        }
        
        // Calculate actual total distance based on segments
        let actualDistance = segments.reduce(0) { $0 + $1.distance }
        
        // Optionally warn if fallback segments were used
        if fallbackSegmentsUsed {
            print("⚠️ Route created with some fallback segments. Navigation accuracy may be affected.")
        }
        
        // Validate the final route
        guard !segments.isEmpty else {
            throw RouteError.noRouteFound
        }
        
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
           // usesFallbackSegments: fallbackSegmentsUsed
        )
    }
    
    // Australia - Coastal Walk
    private static func createBondiToBronteRoute() async throws -> VirtualRoute {
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
    private static func createTableMountainRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.tableMount,
            name: "Table Mountain Platteklip Gorge",
            description: "Direct route to the summit of Table Mountain via the iconic Platteklip Gorge",
            totalDistance: 5.500, // More accurate total distance
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
                    name: "First View Point",
                    description: "First major viewpoint offering spectacular views of Lion's Head and the city below.",
                    distanceFromStart: 1.800,
                    imageName: "table-mountain"
                ),
                RouteMilestone(
                    routeId: RouteConstants.tableMount,
                    name: "Halfway Point",
                    description: "A natural resting spot with space to catch your breath. The gorge's impressive rock walls tower above you.",
                    distanceFromStart: 2.750,
                    imageName: "table-mountain"
                ),
                RouteMilestone(
                    routeId: RouteConstants.tableMount,
                    name: "Upper Plateau",
                    description: "The point where you emerge from the gorge onto the upper plateau. The gradient eases here as you approach the summit.",
                    distanceFromStart: 4.200,
                    imageName: "table-mountain"
                ),
                RouteMilestone(
                    routeId: RouteConstants.tableMount,
                    name: "Table Mountain Summit",
                    description: "The iconic flat-topped peak offering breathtaking 360-degree views of Cape Town, the Atlantic Ocean, and neighboring peaks. Home to unique fynbos vegetation and elusive rock hyraxes.",
                    distanceFromStart: 5.500,
                    imageName: "table-summit"
                )
            ],
            imageName: "table-mountain",
            region: "South Africa",
            waypoints: [
                CLLocationCoordinate2D(latitude: -33.9566, longitude: 18.4041),  // Start at Tafelberg Road
                CLLocationCoordinate2D(latitude: -33.9571, longitude: 18.4045),  // Initial ascent
                CLLocationCoordinate2D(latitude: -33.9575, longitude: 18.4049),  // First viewpoint
                CLLocationCoordinate2D(latitude: -33.9579, longitude: 18.4052),  // Lower gorge
                CLLocationCoordinate2D(latitude: -33.9582, longitude: 18.4055),  // Middle gorge
                CLLocationCoordinate2D(latitude: -33.9585, longitude: 18.4058),  // Upper gorge
                CLLocationCoordinate2D(latitude: -33.9588, longitude: 18.4061),  // Emerge from gorge
                CLLocationCoordinate2D(latitude: -33.9592, longitude: 18.4064),  // Upper plateau
                CLLocationCoordinate2D(latitude: -33.9577, longitude: 18.4058)   // Summit
            ]
        )
    }
    
    // USA - Historical City Walk
    private static func createBostonFreedomRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.bostonFreedom,
            name: "Boston Freedom Trail",
            description: "Walk through history on Boston's iconic Freedom Trail",
            totalDistance: 4.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "Boston Common",
                    description: "America's oldest public park, established in 1634. Once a cattle grazing ground, it's now the starting point of the Freedom Trail and a vibrant urban green space in the heart of Boston.",
                    distanceFromStart: 0,
                    imageName: "boston-common"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "Paul Revere House",
                    description: "The oldest remaining structure in downtown Boston (c. 1680) and home to Revolutionary War hero Paul Revere. This remarkably preserved colonial dwelling offers a glimpse into 18th-century Boston life.",
                    distanceFromStart: 2.500,
                    imageName: "paul-revere"
                ),
                RouteMilestone(
                    routeId: RouteConstants.bostonFreedom,
                    name: "USS Constitution",
                    description: "The world's oldest commissioned warship still afloat (1797). 'Old Ironsides' earned her nickname during the War of 1812 and continues to be a symbol of American naval excellence.",
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
    
    // Japan - Cultural Walk
    private static func createKyotoPhilosophersRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.kyotoPhilosophersPath,
            name: "Philosopher's Path",
            description: """
            A peaceful 2-kilometer stone path through northern Kyoto, named after philosopher Nishida Kitaro \
            who meditated while walking this route to Kyoto University. The path follows a cherry-tree-lined \
            canal and connects several significant temples, offering a contemplative journey through historic \
            eastern Kyoto.
            """,
            totalDistance: 2.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Ginkaku-ji",
                    description: """
                    The Silver Pavilion, a Zen temple of extraordinary beauty. Its minimalist design, moss garden, \
                    and sand sculptures exemplify Japanese aesthetics and the pursuit of perfection in simplicity. \
                    The temple's Sea of Silver Sand and Moon Viewing Platform are particularly notable features.
                    """,
                    distanceFromStart: 0,
                    imageName: "ginkakuji"
                ),
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Honen-in Temple",
                    description: """
                    A serene temple famous for its moss-covered entry gates and seasonal gardens. The thatched \
                    gate entrance features carefully raked sand patterns that change with the seasons. The temple \
                    regularly hosts modern art exhibitions in its halls.
                    """,
                    distanceFromStart: 0.400,
                    imageName: "honenin"
                ),
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Anraku-ji Temple",
                    description: """
                    A small but significant temple dedicated to the Buddhist nun Anraku. Known for its beautiful \
                    garden and connection to the history of women in Japanese Buddhism.
                    """,
                    distanceFromStart: 0.800,
                    imageName: "anrakuji"
                ),
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Eikan-do Zenrin-ji",
                    description: """
                    Famous for its autumn colors and unique statue of the Amida Buddha looking backward over his \
                    shoulder. The temple features multiple halls connected by covered walkways, a pond garden, and \
                    a pagoda offering panoramic views of Kyoto.
                    """,
                    distanceFromStart: 1.500,
                    imageName: "eikando"
                ),
                RouteMilestone(
                    routeId: RouteConstants.kyotoPhilosophersPath,
                    name: "Nanzen-ji",
                    description: """
                    One of Japan's most important Zen temples, featuring magnificent gates, a surprising aqueduct, \
                    and tranquil rock gardens. The temple grounds offer a perfect blend of architecture and nature. \
                    The massive Sanmon gate and the unexpected brick aqueduct showcase the temple's historical \
                    significance and architectural diversity.
                    """,
                    distanceFromStart: 2.000,
                    imageName: "nanzenji"
                )
            ],
            imageName: "philosophers-path",
            region: "Japan",
            waypoints: [
                CLLocationCoordinate2D(latitude: 35.0271, longitude: 135.7944), // Ginkaku-ji
                CLLocationCoordinate2D(latitude: 35.0262, longitude: 135.7941), // Honen-in
                CLLocationCoordinate2D(latitude: 35.0245, longitude: 135.7938), // Anraku-ji
                CLLocationCoordinate2D(latitude: 35.0147, longitude: 135.7934), // Eikan-do
                CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7932)  // Nanzen-ji
            ]
        )
    }
    
    // Create routes with segments
    private static func createCaminoRoute() async throws -> VirtualRoute {
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
    
    private static func createHighCoastRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.highCoast,
            name: "Höga Kusten Trail - Coastal Section",
            description: """
            A scenic 12km coastal section of Sweden's High Coast Trail (Höga Kustenleden), featuring dramatic \
            coastline views, historic fishing villages, and UNESCO World Heritage sites. This segment offers \
            moderate difficulty with well-maintained paths.
            """,
            totalDistance: 12.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.highCoast,
                    name: "Hornöberget",
                    description: """
                    Starting point offering panoramic views of the Baltic Sea and surrounding islands. Features \
                    interpretive signs about the area's unique geology and land uplift phenomenon.
                    """,
                    distanceFromStart: 0,
                    imageName: "hornoberget"
                ),
                RouteMilestone(
                    routeId: RouteConstants.highCoast,
                    name: "Rotsidan Nature Reserve",
                    description: """
                    Famous for its smooth, wave-washed rocks and coastal meadows. The distinctive shoreline \
                    showcases the effects of post-glacial rebound, raising the coast by nearly 300 meters.
                    """,
                    distanceFromStart: 3.500,
                    imageName: "rotsidan"
                ),
                RouteMilestone(
                    routeId: RouteConstants.highCoast,
                    name: "Bönhamn Fishing Village",
                    description: """
                    Historic fishing village with well-preserved traditional buildings and boat houses. \
                    Offers facilities including a café, rest areas, and insights into local maritime culture.
                    """,
                    distanceFromStart: 6.000,
                    imageName: "bonhamn"
                ),
                RouteMilestone(
                    routeId: RouteConstants.highCoast,
                    name: "Högklinten Viewpoint",
                    description: """
                    One of the trail's highest points, offering spectacular views of the High Coast Bridge \
                    and surrounding archipelago. Features picnic areas and information about local wildlife.
                    """,
                    distanceFromStart: 9.000,
                    imageName: ""
                ),
                RouteMilestone(
                    routeId: RouteConstants.highCoast,
                    name: "Norrfällsviken",
                    description: """
                    Beautiful fishing village and endpoint of this section, featuring sandy beaches, historic \
                    chapel, and camping facilities. Popular spot for swimming in summer months.
                    """,
                    distanceFromStart: 12.000,
                    imageName: "norrfallsviken"
                )
            ],
            imageName: "high-coast-trail",
            region: "Sweden",
            waypoints: [
                CLLocationCoordinate2D(latitude: 62.9271, longitude: 18.2614), // Hornöberget
                CLLocationCoordinate2D(latitude: 62.9158, longitude: 18.2425), // Rotsidan
                CLLocationCoordinate2D(latitude: 62.8986, longitude: 18.2347), // Bönhamn
                CLLocationCoordinate2D(latitude: 62.8869, longitude: 18.2469), // Högklinten
                CLLocationCoordinate2D(latitude: 62.8733, longitude: 18.2528)  // Norrfällsviken
            ]
        )
    }
    
    // Canada - Urban Nature Walk
    private static func createVancouverSeawallRoute() async throws -> VirtualRoute {
        return try await createRouteWithSegments(
            id: RouteConstants.vancouverSeawall,
            name: "Stanley Park Seawall",
            description: "Scenic waterfront path around Vancouver's Stanley Park",
            totalDistance: 10.000,
            milestones: [
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "Coal Harbour",
                    description: "A sophisticated waterfront neighborhood offering stunning views of the North Shore mountains, float planes taking off, and luxury yachts. The starting point showcases Vancouver's blend of urban and natural beauty.",
                    distanceFromStart: 0,
                    imageName: ""
                ),
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "Lions Gate Bridge",
                    description: "An iconic suspension bridge connecting Vancouver to the North Shore. This National Historic Site offers spectacular views of Stanley Park, the harbor, and the city skyline.",
                    distanceFromStart: 5.000,
                    imageName: ""
                ),
                RouteMilestone(
                    routeId: RouteConstants.vancouverSeawall,
                    name: "English Bay",
                    description: "A vibrant beach area famous for stunning sunsets and the annual Celebration of Light fireworks competition. Popular among cyclists, swimmers, and beach volleyball enthusiasts.",
                    distanceFromStart: 10.000,
                    imageName: ""
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
    
    
    
    // South Korea - Urban Historical
    private static func createSeoulCityWallRoute() async throws -> VirtualRoute {
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
}


