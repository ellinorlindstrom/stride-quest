import Foundation
import CoreLocation
import MapKit

// MARK: - Errors
enum RouteError: Error {
    case noRouteFound
    case invalidCoordinate
    case invalidDistance
    case maxRetriesExceeded(underlyingError: Error?)
    case networkError(Error)
    
    var errorDescription: String {
        switch self {
        case .noRouteFound:
            return "No route could be found between the specified locations"
        case .invalidCoordinate:
            return "The provided coordinates are invalid"
        case .invalidDistance:
            return "The provided distance is invalid"
        case .maxRetriesExceeded(let error):
            return "Failed to find route after multiple attempts. Last error: \(error?.localizedDescription ?? "Unknown")"
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        }
    }
}


// MARK: - Protocols
protocol Coordinate {
    var latitude: Double { get }
    var longitude: Double { get }
    var coordinate: CLLocationCoordinate2D { get }
}

protocol Route {
    var id: UUID { get }
    var totalDistance: Double { get }
    var path: [CLLocationCoordinate2D] { get }
    func coordinate(at distance: Double) -> CLLocationCoordinate2D?
}

// MARK: - Coordinate Helper
struct CodableCoordinate: Codable, Hashable, Coordinate {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

// MARK: - Route Segment
struct RouteSegment: Codable, Identifiable, Hashable {
    let id: UUID
    let coordinates: [CodableCoordinate]
    
    var path: [CLLocationCoordinate2D] {
        coordinates.map(\.coordinate)
    }
    
    var distance: Double {
        var totalDistance: Double = 0
        let coordinates = self.path
        
        for i in 0..<(coordinates.count - 1) {
            let start = coordinates[i]
            let end = coordinates[i + 1]
            totalDistance += RouteUtils.calculateDistance(from: start, to: end)
        }
        return totalDistance
    }
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.id = UUID()
        self.coordinates = coordinates.map(CodableCoordinate.init)
    }
}

// MARK: - Virtual Route
struct VirtualRoute: Route, Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let totalDistance: Double
    let milestones: [RouteMilestone]
    let imageName: String
    let region: String
    private let codableStartCoordinate: CodableCoordinate
    private let codableWaypoints: [CodableCoordinate]
    let segments: [RouteSegment]
    
    var startCoordinate: CLLocationCoordinate2D { codableStartCoordinate.coordinate }
    var waypoints: [CLLocationCoordinate2D] { codableWaypoints.map(\.coordinate) }
    var path: [CLLocationCoordinate2D] { segments.flatMap(\.path) }
    
    static func == (lhs: VirtualRoute, rhs: VirtualRoute) -> Bool {
            lhs.id == rhs.id
        }
    
    init(id: UUID = UUID(),
         name: String,
         description: String,
         totalDistance: Double,
         milestones: [RouteMilestone],
         imageName: String,
         region: String,
         startCoordinate: CLLocationCoordinate2D,
         waypoints: [CLLocationCoordinate2D],
         segments: [RouteSegment]) {
        self.id = id
        self.name = name
        self.description = description
        self.totalDistance = totalDistance
        self.milestones = milestones.map { $0.with(routeId: id) }
        self.imageName = imageName
        self.region = region
        self.codableStartCoordinate = CodableCoordinate(coordinate: startCoordinate)
        self.codableWaypoints = waypoints.map(CodableCoordinate.init)
        self.segments = segments
    }
    
    func coordinate(at distance: Double) -> CLLocationCoordinate2D? {
        RouteUtils.findCoordinate(distance: distance, in: self)
    }
}

// MARK: - Route Milestone
struct RouteMilestone: Identifiable, Codable, Equatable {
    let id: UUID
    let routeId: UUID
    let name: String
    let description: String
    let distanceFromStart: Double
    let imageName: String
    
    static func == (lhs: RouteMilestone, rhs: RouteMilestone) -> Bool {
            lhs.id == rhs.id
        }
    
    init(id: UUID = UUID(),
         routeId: UUID,
         name: String,
         description: String,
         distanceFromStart: Double,
         imageName: String) {
        self.id = id
        self.routeId = routeId
        self.name = name
        self.description = description
        self.distanceFromStart = distanceFromStart
        self.imageName = imageName
    }
    
    func with(routeId: UUID) -> RouteMilestone {
        RouteMilestone(
            id: id,
            routeId: routeId,
            name: name,
            description: description,
            distanceFromStart: distanceFromStart,
            imageName: imageName
        )
    }
}

// MARK: - Route Progress
struct RouteProgress: Codable {
    // MARK: - Nested Types
    struct DailyProgress: Codable {
        let date: Date
        var distance: Double
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Properties
    let id: UUID
    let routeId: UUID
    let totalDistance: Double
    private(set) var startDate: Date
    private(set) var completedDistance: Double
    private(set) var lastUpdated: Date
    private(set) var completedMilestones: Set<UUID>
    private(set) var dailyProgress: [String: Double]
    private(set) var isDistanceCompleted: Bool
    private(set) var isCompleted: Bool
    private(set) var completionDate: Date?
    
    // MARK: - Computed Properties
    var percentageCompleted: Double {
        (min(completedDistance, totalDistance) / totalDistance) * 100
    }
    
    var remainingDistance: Double {
        max(0, totalDistance - completedDistance)
    }
    
    var completedPath: [CLLocationCoordinate2D] {
        guard let route = RouteManager.shared.getRoute(by: routeId),
              completedDistance > 0 else {
            return []
        }
        
        return route.path.prefix { coordinate in
            let startCoord = route.startCoordinate
            let location1 = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
            let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return location1.distance(from: location2) <= min(completedDistance, totalDistance)
        }
    }
    
    var dailyProgressArray: [DailyProgress] {
        dailyProgress.compactMap { dateString, distance in
            guard let date = Self.dateFormatter.date(from: dateString) else { return nil }
            return DailyProgress(date: date, distance: distance)
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Initialization
    init(id: UUID = UUID(),
         routeId: UUID,
         startDate: Date,
         completedDistance: Double = 0,
         lastUpdated: Date,
         completedMilestones: Set<UUID> = [],
         totalDistance: Double,
         dailyProgress: [String: Double] = [:],
         isDistanceCompleted: Bool = false,
         isCompleted: Bool = false,
         completionDate: Date? = nil) {
        self.id = id
        self.routeId = routeId
        self.startDate = startDate
        self.completedDistance = completedDistance
        self.lastUpdated = lastUpdated
        self.completedMilestones = completedMilestones
        self.totalDistance = totalDistance
        self.dailyProgress = dailyProgress
        self.isDistanceCompleted = isDistanceCompleted
        self.isCompleted = isCompleted
        self.completionDate = completionDate
    }
    
    // MARK: - Progress Update Methods
    mutating func updateProgress(distance: Double, date: Date) {
        let cappedDistance = min(distance, totalDistance)
        completedDistance += distance
        lastUpdated = date
        
        let dateString = Self.dateFormatter.string(from: date)
        dailyProgress[dateString, default: 0] = cappedDistance
        
        checkDistanceCompletion(at: cappedDistance)
    }
    
    mutating func updateDailyProgress(distance: Double, for date: String) {
        let cappedDistance = min(distance, totalDistance)
        dailyProgress[date] = cappedDistance
    }

        mutating func updateCompletedDistance(_ distance: Double, isManual: Bool) {
            let cappedDistance = min(distance, totalDistance)
            completedDistance = isManual ? cappedDistance : min(cappedDistance, totalDistance)
            lastUpdated = Date()
            
            checkDistanceCompletion(at: completedDistance)
        }
    
    mutating func markCompleted() {
        isCompleted = true
        completionDate = Date()
    }
    
    mutating func addCompletedMilestone(_ id: UUID) {
        completedMilestones.insert(id)
    }
    
    mutating func finalizeCompletion() {
            guard isDistanceCompleted && !isCompleted else { return }
            isCompleted = true
            completionDate = Date()
        }
    
    // MARK: - Private Helpers
    private mutating func checkDistanceCompletion(at distance: Double) {
            if distance >= totalDistance && !isDistanceCompleted {
                isDistanceCompleted = true
            }
    }
}
