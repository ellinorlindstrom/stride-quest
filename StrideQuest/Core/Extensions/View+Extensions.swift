import Foundation
import CoreLocation

extension RouteManager {
    func initializeRoutes() -> [VirtualRoute] {
        [
            VirtualRoute(
                name: "Camino de Santiago",
                description: "Follow the historic pilgrimage route through Spain",
                totalDistance: 799000,
                milestones: [
                    RouteMilestone(
                        name: "Pamplona",
                        description: "Historic city famous for the Running of the Bulls",
                        distanceFromStart: 199750,
                        imageName: "pamplona"
                    ),
                    RouteMilestone(
                        name: "Burgos Cathedral",
                        description: "UNESCO World Heritage Gothic cathedral",
                        distanceFromStart: 399500,
                        imageName: "burgos"
                    ),
                    RouteMilestone(
                        name: "Santiago de Compostela",
                        description: "Final destination with its famous cathedral",
                        distanceFromStart: 799000,
                        imageName: "santiago"
                    )
                ],
                imageName: "camino",
                region: "Spain",
                startCoordinate: CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358),
                coordinates: [
                    CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358),
                    CLLocationCoordinate2D(latitude: 42.8188, longitude: -1.6444),
                    CLLocationCoordinate2D(latitude: 42.3439, longitude: -3.6966),
                    CLLocationCoordinate2D(latitude: 42.8805, longitude: -8.5459)
                ]
            ),
            
            VirtualRoute(
                name: "Great Wall Adventure",
                description: "Trek along sections of China's Great Wall",
                totalDistance: 42000,
                milestones: [
                    RouteMilestone(
                        name: "Mutianyu",
                        description: "Well-preserved section with stunning views",
                        distanceFromStart: 14000,
                        imageName: "mutianyu"
                    ),
                    RouteMilestone(
                        name: "Watchtower 23",
                        description: "Historic defensive position",
                        distanceFromStart: 28000,
                        imageName: "watchtower"
                    ),
                    RouteMilestone(
                        name: "Jinshanling",
                        description: "Most picturesque section of the wall",
                        distanceFromStart: 42000,
                        imageName: "jinshanling"
                    )
                ],
                imageName: "great_wall",
                region: "China",
                startCoordinate: CLLocationCoordinate2D(latitude: 40.4319, longitude: 116.5704),
                coordinates: [
                    CLLocationCoordinate2D(latitude: 40.4319, longitude: 116.5704),
                    CLLocationCoordinate2D(latitude: 40.4765, longitude: 116.5998),
                    CLLocationCoordinate2D(latitude: 40.6764, longitude: 117.2754)
                ]
            ),
            
            VirtualRoute(
                name: "Great Ocean Walk",
                description: "Coastal journey along Australia's southern edge",
                totalDistance: 104000,
                milestones: [
                    RouteMilestone(
                        name: "Twelve Apostles",
                        description: "Iconic limestone stacks",
                        distanceFromStart: 34666,
                        imageName: "twelve_apostles"
                    ),
                    RouteMilestone(
                        name: "Cape Otway",
                        description: "Historic lighthouse and koala habitat",
                        distanceFromStart: 69333,
                        imageName: "cape_otway"
                    ),
                    RouteMilestone(
                        name: "Apollo Bay",
                        description: "Beautiful coastal town finish",
                        distanceFromStart: 104000,
                        imageName: "apollo_bay"
                    )
                ],
                imageName: "great_ocean",
                region: "Australia",
                startCoordinate: CLLocationCoordinate2D(latitude: -38.6621, longitude: 143.1047),
                coordinates: [
                    CLLocationCoordinate2D(latitude: -38.6621, longitude: 143.1047),
                    CLLocationCoordinate2D(latitude: -38.8566, longitude: 143.5287),
                    CLLocationCoordinate2D(latitude: -38.7570, longitude: 143.6696)
                ]
            ),
            
            VirtualRoute(
                name: "Appalachian Trail Section",
                description: "Experience a portion of America's oldest marked hiking trail",
                totalDistance: 161000,
                milestones: [
                    RouteMilestone(
                        name: "McAfee Knob",
                        description: "Most photographed spot on the trail",
                        distanceFromStart: 53666,
                        imageName: "mcafee"
                    ),
                    RouteMilestone(
                        name: "Shenandoah Valley",
                        description: "Breathtaking valley views",
                        distanceFromStart: 107333,
                        imageName: "shenandoah"
                    ),
                    RouteMilestone(
                        name: "Mount Katahdin",
                        description: "Northern terminus of the trail",
                        distanceFromStart: 161000,
                        imageName: "katahdin"
                    )
                ],
                imageName: "appalachian",
                region: "USA",
                startCoordinate: CLLocationCoordinate2D(latitude: 37.3930, longitude: -80.0363),
                coordinates: [
                    CLLocationCoordinate2D(latitude: 37.3930, longitude: -80.0363),
                    CLLocationCoordinate2D(latitude: 38.9217, longitude: -78.1987),
                    CLLocationCoordinate2D(latitude: 45.9044, longitude: -68.9213)
                ]
            ),
            
            VirtualRoute(
                name: "Pacific Crest Trail Segment",
                description: "Experience a portion of the iconic Pacific Crest Trail",
                totalDistance: 160934,
                milestones: [
                    RouteMilestone(
                        name: "Mountain View Point",
                        description: "Spectacular valley views",
                        distanceFromStart: 32186.9,
                        imageName: "mountain_view"
                    ),
                    RouteMilestone(
                        name: "Alpine Lake",
                        description: "Crystal clear mountain lake",
                        distanceFromStart: 80467.2,
                        imageName: "alpine_lake"
                    ),
                    RouteMilestone(
                        name: "Summit Peak",
                        description: "Highest point of the journey",
                        distanceFromStart: 128747.5,
                        imageName: "summit"
                    )
                ],
                imageName: "pct_preview",
                region: "Western USA",
                startCoordinate: CLLocationCoordinate2D(latitude: 41.8456, longitude: -122.5382),
                coordinates: [
                    CLLocationCoordinate2D(latitude: 41.8456, longitude: -122.5382),
                    CLLocationCoordinate2D(latitude: 42.0540, longitude: -122.6153),
                    CLLocationCoordinate2D(latitude: 42.9187, longitude: -122.1685)
                ]
            ),
            
            VirtualRoute(
                name: "Inca Trail",
                description: "Journey to Machu Picchu through the Andes",
                totalDistance: 43000,
                milestones: [
                    RouteMilestone(
                        name: "Dead Woman's Pass",
                        description: "Highest point of the trail",
                        distanceFromStart: 14333,
                        imageName: "dead_womans_pass"
                    ),
                    RouteMilestone(
                        name: "Wiñay Wayna",
                        description: "Beautiful Inca ruins",
                        distanceFromStart: 28666,
                        imageName: "winay_wayna"
                    ),
                    RouteMilestone(
                        name: "Machu Picchu",
                        description: "The lost city of the Incas",
                        distanceFromStart: 43000,
                        imageName: "machu_picchu"
                    )
                ],
                imageName: "inca_trail",
                region: "Peru",
                startCoordinate: CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784),
                coordinates: [
                    CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784),
                    CLLocationCoordinate2D(latitude: -13.1868, longitude: -72.5508),
                    CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5449)
                ]
            )
        ]
    }
}
