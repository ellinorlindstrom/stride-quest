import Foundation
import CoreLocation

extension RouteManager {
    func initializeRoutes() -> [VirtualRoute] {
        
        let caminoId = UUID()
        let greatWallId = UUID()
        let pacificCrestTrailId = UUID()
        let incaTrailId = UUID()
        
        return
       [
        VirtualRoute(
            id: caminoId,
            name: "Camino de Santiago",
            description: "Follow the historic pilgrimage route through Spain",
            totalDistance: 825000, // Corrected to actual distance
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
                    name: "Roncesvalles",
                    description: "First Spanish town and historic monastery",
                    distanceFromStart: 27500, // ~27.5km - actual first day's challenging hike
                    imageName: "roncesvalles"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Zubiri",
                    description: "Medieval bridge town",
                    distanceFromStart: 48500,
                    imageName: "zubiri"
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
                    name: "Puente la Reina",
                    description: "Town with famous Romanesque bridge",
                    distanceFromStart: 100000,
                    imageName: "puente-la-reina"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Estella",
                    description: "Historic town with beautiful churches",
                    distanceFromStart: 126000,
                    imageName: "estella"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Los Arcos",
                    description: "Medieval town with Gothic church",
                    distanceFromStart: 152000,
                    imageName: "los-arcos"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Logroño",
                    description: "Capital of La Rioja wine region",
                    distanceFromStart: 178000,
                    imageName: "logrono"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Santo Domingo de la Calzada",
                    description: "Town with cathedral and famous chicken legend",
                    distanceFromStart: 204000,
                    imageName: "santo-domingo"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Belorado",
                    description: "Ancient settlement with castle ruins",
                    distanceFromStart: 230000,
                    imageName: "belorado"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "San Juan de Ortega",
                    description: "12th-century monastery",
                    distanceFromStart: 256000,
                    imageName: "san-juan"
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
                    name: "Castrojeriz",
                    description: "Hill town with castle ruins",
                    distanceFromStart: 308000,
                    imageName: "castrojeriz"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Frómista",
                    description: "Perfect Romanesque church of San Martín",
                    distanceFromStart: 334000,
                    imageName: "fromista"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Carrión de los Condes",
                    description: "Medieval town with Romanesque churches",
                    distanceFromStart: 360000,
                    imageName: "carrion"
                ),
                RouteMilestone(
                    routeId: caminoId,
                    name: "Sahagún",
                    description: "Town known as the Spanish Cluny",
                    distanceFromStart: 386000,
                    imageName: "sahagun"
                ),
                
            ],
            imageName: "camino-de-santiago",
                region: "Spain",
                startCoordinate: CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358),
                waypoints: [
                    // France to Pamplona
                    CLLocationCoordinate2D(latitude: 43.1631, longitude: -1.2358), // Saint-Jean-Pied-de-Port
                    CLLocationCoordinate2D(latitude: 43.1589, longitude: -1.2401), // Rue de la Citadelle
                    CLLocationCoordinate2D(latitude: 43.1522, longitude: -1.2498), // Start of mountain ascent
                    CLLocationCoordinate2D(latitude: 43.1420, longitude: -1.2612), // Huntto
                    CLLocationCoordinate2D(latitude: 43.1318, longitude: -1.2789), // Orisson
                    CLLocationCoordinate2D(latitude: 43.1209, longitude: -1.2901), // Mountain pass approach
                    CLLocationCoordinate2D(latitude: 43.1087, longitude: -1.3012), // Col de Lepoeder
                    CLLocationCoordinate2D(latitude: 43.0097, longitude: -1.3192), // Roncesvalles
                    CLLocationCoordinate2D(latitude: 42.9988, longitude: -1.3318), // Burguete
                    CLLocationCoordinate2D(latitude: 42.9782, longitude: -1.3672), // Espinal
                    CLLocationCoordinate2D(latitude: 42.9402, longitude: -1.4144), // Viskarret
                    CLLocationCoordinate2D(latitude: 42.9182, longitude: -1.4834), // Zubiri
                    CLLocationCoordinate2D(latitude: 42.8988, longitude: -1.5156), // Larrasoaña
                    CLLocationCoordinate2D(latitude: 42.8822, longitude: -1.5399), // Zabaldika
                    CLLocationCoordinate2D(latitude: 42.8188, longitude: -1.6444), // Pamplona

                    // Pamplona to Logroño
                    CLLocationCoordinate2D(latitude: 42.8011, longitude: -1.7234), // Cizur Menor
                    CLLocationCoordinate2D(latitude: 42.7723, longitude: -1.7892), // Alto del Perdón
                    CLLocationCoordinate2D(latitude: 42.7432, longitude: -1.8156), // Uterga
                    CLLocationCoordinate2D(latitude: 42.6726, longitude: -1.8912), // Puente la Reina
                    CLLocationCoordinate2D(latitude: 42.6556, longitude: -1.9488), // Mañeru
                    CLLocationCoordinate2D(latitude: 42.6721, longitude: -2.0281), // Cirauqui
                    CLLocationCoordinate2D(latitude: 42.6532, longitude: -2.0912), // Lorca
                    CLLocationCoordinate2D(latitude: 42.6126, longitude: -2.1668), // Estella
                    CLLocationCoordinate2D(latitude: 42.5723, longitude: -2.2701), // Los Arcos
                    CLLocationCoordinate2D(latitude: 42.5012, longitude: -2.3445), // Sansol
                    CLLocationCoordinate2D(latitude: 42.4668, longitude: -2.4449), // Logroño

                    // Logroño to Burgos
                    CLLocationCoordinate2D(latitude: 42.4466, longitude: -2.5567), // Navarrete
                    CLLocationCoordinate2D(latitude: 42.4312, longitude: -2.7234), // Nájera
                    CLLocationCoordinate2D(latitude: 42.4201, longitude: -2.9512), // Santo Domingo de la Calzada
                    CLLocationCoordinate2D(latitude: 42.4102, longitude: -3.1892), // Belorado
                    CLLocationCoordinate2D(latitude: 42.3756, longitude: -3.3234), // San Juan de Ortega
                    CLLocationCoordinate2D(latitude: 42.3439, longitude: -3.6966), // Burgos

                    // Burgos to León
                    CLLocationCoordinate2D(latitude: 42.3378, longitude: -3.9882), // Hornillos del Camino
                    CLLocationCoordinate2D(latitude: 42.3412, longitude: -4.1456), // Castrojeriz
                    CLLocationCoordinate2D(latitude: 42.3689, longitude: -4.3234), // Frómista
                    CLLocationCoordinate2D(latitude: 42.3401, longitude: -4.6012), // Carrión de los Condes
                    CLLocationCoordinate2D(latitude: 42.3712, longitude: -4.8734), // Sahagún
                    CLLocationCoordinate2D(latitude: 42.4982, longitude: -5.5773), // León

                    // León to Ponferrada
                    CLLocationCoordinate2D(latitude: 42.4892, longitude: -5.7234), // Hospital de Órbigo
                    CLLocationCoordinate2D(latitude: 42.4567, longitude: -5.9456), // Astorga
                    CLLocationCoordinate2D(latitude: 42.4789, longitude: -6.1892), // Rabanal del Camino
                    CLLocationCoordinate2D(latitude: 42.5123, longitude: -6.3234), // Cruz de Ferro
                    CLLocationCoordinate2D(latitude: 42.5456, longitude: -6.5892), // El Acebo
                    CLLocationCoordinate2D(latitude: 42.5987, longitude: -6.7327), // Ponferrada

                    // Ponferrada to O Cebreiro
                    CLLocationCoordinate2D(latitude: 42.6234, longitude: -6.8892), // Villafranca del Bierzo
                    CLLocationCoordinate2D(latitude: 42.6567, longitude: -7.0234), // La Faba
                    CLLocationCoordinate2D(latitude: 42.7012, longitude: -7.1712), // O Cebreiro

                    // O Cebreiro to Santiago
                    CLLocationCoordinate2D(latitude: 42.7234, longitude: -7.2344), // Triacastela
                    CLLocationCoordinate2D(latitude: 42.7469, longitude: -7.4154), // Sarria
                    CLLocationCoordinate2D(latitude: 42.7612, longitude: -7.5892), // Portomarín
                    CLLocationCoordinate2D(latitude: 42.7889, longitude: -7.7234), // Palas de Rei
                    CLLocationCoordinate2D(latitude: 42.8123, longitude: -7.8892), // Melide
                    CLLocationCoordinate2D(latitude: 42.8345, longitude: -8.1234), // Arzúa
                    CLLocationCoordinate2D(latitude: 42.8567, longitude: -8.3892), // O Pedrouzo
                    CLLocationCoordinate2D(latitude: 42.8712, longitude: -8.4712), // Monte do Gozo
                    CLLocationCoordinate2D(latitude: 42.8805, longitude: -8.5459)  // Santiago de Compostela
                ],
            segments: []
            ),
        
        VirtualRoute(
            id: greatWallId,
            name: "Great Wall Adventure",
            description: "Trek along sections of China's Great Wall from Mutianyu to Jinshanling",
            totalDistance: 65000,
            milestones: [
                RouteMilestone(
                 routeId: greatWallId,
                    name: "Mutianyu Entrance",
                    description: "Starting point at the restored Mutianyu section",
                    distanceFromStart: 0,
                    imageName: "mutianyu_entrance"
                ),
                RouteMilestone(
                 routeId: greatWallId,
                    name: "Tower 6",
                    description: "Scenic viewpoint of mountain ranges",
                    distanceFromStart: 850,
                    imageName: "tower_6"
                ),
                RouteMilestone(
                 routeId: greatWallId,
                    name: "Tower 14",
                    description: "Highest point of Mutianyu section",
                    distanceFromStart: 1800,
                    imageName: "tower_14"
                )
            ],
            imageName: "great-wall-adventure", 
            region: "China",
            startCoordinate: CLLocationCoordinate2D(latitude: 40.4319, longitude: 116.5704), // Mutianyu coordinates
            waypoints: [  // Add key waypoints along the route
                CLLocationCoordinate2D(latitude: 40.4319, longitude: 116.5704), // Mutianyu
                // Add more waypoints as needed
                CLLocationCoordinate2D(latitude: 40.6764, longitude: 117.2372)  // Jinshanling
            ],
            segments: []  // Add segments if you have them, or leave empty
        ),
           
        
            
        VirtualRoute(
            name: "Great Ocean Walk",
            description: "Coastal journey along Australia's southern edge from Apollo Bay to the Twelve Apostles",
            totalDistance: 104000, // 104 km total length
            milestones: [
                RouteMilestone(
                    routeId: UUID(),
                    name: "Apollo Bay Visitor Centre",
                    description: "Starting point of the Great Ocean Walk",
                    distanceFromStart: 0,
                    imageName: "apollo_bay_start"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Marengo Reefs Marine Sanctuary",
                    description: "Protected marine area with Australian fur seals",
                    distanceFromStart: 2500,
                    imageName: "marengo_reefs"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Shelly Beach",
                    description: "Sheltered beach with rich marine life",
                    distanceFromStart: 8000,
                    imageName: "shelly_beach"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Elliot Ridge Campsite",
                    description: "First hiker's campsite in the eucalyptus forest",
                    distanceFromStart: 12000,
                    imageName: "elliot_ridge"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Blanket Bay",
                    description: "Protected bay with pristine beach",
                    distanceFromStart: 21000,
                    imageName: "blanket_bay"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Parker Inlet",
                    description: "Scenic river crossing and wetlands",
                    distanceFromStart: 27500,
                    imageName: "parker_inlet"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Cape Otway Lightstation",
                    description: "Historic lighthouse and koala habitat",
                    distanceFromStart: 34666,
                    imageName: "cape_otway"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Aire River",
                    description: "Major river crossing with wetland birds",
                    distanceFromStart: 42000,
                    imageName: "aire_river"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Castle Cove",
                    description: "Dramatic cliffs and geological formations",
                    distanceFromStart: 48000,
                    imageName: "castle_cove"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Johanna Beach",
                    description: "Long surf beach with rugged coastline",
                    distanceFromStart: 55000,
                    imageName: "johanna_beach"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Milanesia Beach",
                    description: "Remote beach with spectacular cliffs",
                    distanceFromStart: 65000,
                    imageName: "milanesia_beach"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Ryan's Den",
                    description: "Highest sea cliffs in mainland Australia",
                    distanceFromStart: 72000,
                    imageName: "ryans_den"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Devils Kitchen",
                    description: "Challenging coastal section with views",
                    distanceFromStart: 80000,
                    imageName: "devils_kitchen"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Princetown",
                    description: "Coastal village with estuary views",
                    distanceFromStart: 91000,
                    imageName: "princetown"
                ),
                RouteMilestone(
                    routeId: UUID(),
                    name: "Twelve Apostles",
                    description: "Iconic limestone stacks and visitor center",
                    distanceFromStart: 104000,
                    imageName: "twelve_apostles"
                )
            ],
            imageName: "great-ocean-walk",
            region: "Australia",
            startCoordinate: CLLocationCoordinate2D(latitude: -38.7570, longitude: 143.6696),
            waypoints: [
                // Apollo Bay to Marengo
                CLLocationCoordinate2D(latitude: -38.7570, longitude: 143.6696), // Apollo Bay Visitor Centre
                CLLocationCoordinate2D(latitude: -38.7609, longitude: 143.6662), // Apollo Bay Foreshore
                CLLocationCoordinate2D(latitude: -38.7667, longitude: 143.6589), // Marengo Reefs Marine Sanctuary
                
                // To Shelly Beach
                CLLocationCoordinate2D(latitude: -38.7701, longitude: 143.6512), // Wild Dog Creek
                CLLocationCoordinate2D(latitude: -38.7752, longitude: 143.6463), // Three Creeks
                CLLocationCoordinate2D(latitude: -38.7789, longitude: 143.6378), // Shelly Beach
                
                // To Elliot Ridge
                CLLocationCoordinate2D(latitude: -38.7823, longitude: 143.6289), // Forest ascent
                CLLocationCoordinate2D(latitude: -38.7867, longitude: 143.6201), // Elliot Ridge campsite
                
                // To Blanket Bay
                CLLocationCoordinate2D(latitude: -38.7912, longitude: 143.6123), // Crayfish Bay
                CLLocationCoordinate2D(latitude: -38.7956, longitude: 143.6045), // Blanket Bay approach
                CLLocationCoordinate2D(latitude: -38.8012, longitude: 143.5967), // Blanket Bay
                
                // To Parker Inlet
                CLLocationCoordinate2D(latitude: -38.8089, longitude: 143.5878), // Parker Inlet
                CLLocationCoordinate2D(latitude: -38.8156, longitude: 143.5789), // Point Lewis
                CLLocationCoordinate2D(latitude: -38.8234, longitude: 143.5701), // Rainbow Falls
                
                // To Cape Otway
                CLLocationCoordinate2D(latitude: -38.8312, longitude: 143.5612), // Cape Otway Lightstation
                
                // To Aire River
                CLLocationCoordinate2D(latitude: -38.8389, longitude: 143.5523), // Station Beach
                CLLocationCoordinate2D(latitude: -38.8467, longitude: 143.5434), // Aire River estuary
                CLLocationCoordinate2D(latitude: -38.8545, longitude: 143.5345), // Aire River campsite
                
                // To Castle Cove
                CLLocationCoordinate2D(latitude: -38.8623, longitude: 143.5256), // Aire River West
                CLLocationCoordinate2D(latitude: -38.8701, longitude: 143.5167), // Castle Cove lookout
                
                // To Johanna Beach
                CLLocationCoordinate2D(latitude: -38.8778, longitude: 143.5078), // Johanna Beach approach
                CLLocationCoordinate2D(latitude: -38.8856, longitude: 143.4989), // Johanna Beach
                
                // To Milanesia Beach
                CLLocationCoordinate2D(latitude: -38.8934, longitude: 143.4901), // Milanesia track
                CLLocationCoordinate2D(latitude: -38.9012, longitude: 143.4812), // Milanesia Beach
                
                // To Ryan's Den
                CLLocationCoordinate2D(latitude: -38.9089, longitude: 143.4723), // Bowker Point
                CLLocationCoordinate2D(latitude: -38.9167, longitude: 143.4634), // Ryan's Den
                
                // To Devils Kitchen
                CLLocationCoordinate2D(latitude: -38.9245, longitude: 143.4545), // Devil's Kitchen approach
                CLLocationCoordinate2D(latitude: -38.9323, longitude: 143.4456), // Devils Kitchen campsite
                
                // To Princetown
                CLLocationCoordinate2D(latitude: -38.9401, longitude: 143.4367), // The Gables
                CLLocationCoordinate2D(latitude: -38.9478, longitude: 143.4278), // Princetown estuary
                CLLocationCoordinate2D(latitude: -38.9556, longitude: 143.4189), // Princetown
                
                // To Twelve Apostles
                CLLocationCoordinate2D(latitude: -38.9634, longitude: 143.4101), // Gibson Steps approach
                CLLocationCoordinate2D(latitude: -38.9712, longitude: 143.4012), // Gibson Steps
                CLLocationCoordinate2D(latitude: -38.6634, longitude: 143.1051)  // Twelve Apostles Visitor Centre
            ],
            segments: []
        ),
            
            VirtualRoute(
                name: "Appalachian Trail Section",
                description: "Experience a portion of America's oldest marked hiking trail",
                totalDistance: 161000,
                milestones: [
                    RouteMilestone(
                        routeId: UUID(),
                        name: "McAfee Knob",
                        description: "Most photographed spot on the trail",
                        distanceFromStart: 53666,
                        imageName: "mcafee"
                    ),
                    RouteMilestone(
                        routeId: UUID(),
                        name: "Shenandoah Valley",
                        description: "Breathtaking valley views",
                        distanceFromStart: 107333,
                        imageName: "shenandoah"
                    ),
                    RouteMilestone(
                        routeId: UUID(),
                        name: "Mount Katahdin",
                        description: "Northern terminus of the trail",
                        distanceFromStart: 161000,
                        imageName: "katahdin"
                    )
                ],
                imageName: "appalachian-trail-section",
                region: "USA",
                startCoordinate: CLLocationCoordinate2D(latitude: 37.3930, longitude: -80.0363),
                waypoints: [
                    CLLocationCoordinate2D(latitude: 37.3930, longitude: -80.0363),
                    CLLocationCoordinate2D(latitude: 38.9217, longitude: -78.1987),
                    CLLocationCoordinate2D(latitude: 45.9044, longitude: -68.9213)
                ],
                segments: []
            ),
            
            VirtualRoute(
                id: pacificCrestTrailId,
                name: "Pacific Crest Trail Segment",
                description: "Experience a portion of the iconic Pacific Crest Trail",
                totalDistance: 160934,
                milestones: [
                    RouteMilestone(
                        routeId: pacificCrestTrailId,
                        name: "Mountain View Point",
                        description: "Spectacular valley views",
                        distanceFromStart: 32186.9,
                        imageName: "mountain_view"
                    ),
                    RouteMilestone(
                        routeId: pacificCrestTrailId,
                        name: "Alpine Lake",
                        description: "Crystal clear mountain lake",
                        distanceFromStart: 80467.2,
                        imageName: "alpine_lake"
                    ),
                    RouteMilestone(
                        routeId: pacificCrestTrailId,
                        name: "Summit Peak",
                        description: "Highest point of the journey",
                        distanceFromStart: 128747.5,
                        imageName: "summit"
                    )
                ],
                imageName: "pct-segment",
                region: "Western USA",
                startCoordinate: CLLocationCoordinate2D(latitude: 41.8456, longitude: -122.5382),
                waypoints: [
                    CLLocationCoordinate2D(latitude: 41.8456, longitude: -122.5382),
                    CLLocationCoordinate2D(latitude: 42.0540, longitude: -122.6153),
                    CLLocationCoordinate2D(latitude: 42.9187, longitude: -122.1685)
                ],
                segments: []
            ),
            
        VirtualRoute(
            id: incaTrailId,
            name: "Inca Trail to Machu Picchu",
            description: """
            The legendary 4-day trek through the Andes Mountains following ancient Incan paths. 
            Experience breathtaking mountain passes, cloud forests, and ancient ruins before 
            reaching the iconic Machu Picchu. This challenging trail combines stunning natural 
            beauty with fascinating historical sites.
            """,
            totalDistance: 43000,
            milestones: [
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Km 82 (Piscacucho)",
                    description: "The classic starting point of the Inca Trail, where permits are checked and the adventure begins",
                    distanceFromStart: 0,
                    imageName: ""
                ),
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Dead Woman's Pass (Warmiwañusca)",
                    description: "The highest and most challenging point of the trail at 4,215m (13,828ft). Named for its resemblance to a supine woman's profile",
                    distanceFromStart: 14333,
                    imageName: "dead_womans_pass"
                ),
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Wiñay Wayna",
                    description: "Spectacular terraced ruins whose name means 'Forever Young' in Quechua. Features ancient agricultural terraces and religious sites",
                    distanceFromStart: 28666,
                    imageName: "winay_wayna"
                ),
                RouteMilestone(
                    routeId: incaTrailId,
                    name: "Machu Picchu",
                    description: "The legendary 'Lost City of the Incas'. This 15th-century citadel stands as the most famous symbol of Inca civilization",
                    distanceFromStart: 43000,
                    imageName: "machu_picchu"
                )
            ],
            imageName: "inca-trail",
            region: "Cusco Region, Peru",
            startCoordinate: CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784), // Km 82
            //endCoordinate: CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5449), // Machu Picchu
            waypoints: [
                CLLocationCoordinate2D(latitude: -13.5183, longitude: -71.9784), // Start at Km 82
                CLLocationCoordinate2D(latitude: -13.4747, longitude: -72.0304), // Llactapata
                CLLocationCoordinate2D(latitude: -13.4183, longitude: -72.0543), // Wayllabamba
                CLLocationCoordinate2D(latitude: -13.3986, longitude: -72.0912), // Dead Woman's Pass
                CLLocationCoordinate2D(latitude: -13.3602, longitude: -72.1224), // Runkuracay Pass
                CLLocationCoordinate2D(latitude: -13.2937, longitude: -72.1832), // Wiñay Wayna
                CLLocationCoordinate2D(latitude: -13.1868, longitude: -72.5508), // Sun Gate
                CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5449)  // Machu Picchu
            ],
            segments: []
            ),
        ]
        
    }
}
