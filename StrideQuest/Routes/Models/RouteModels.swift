import Foundation
import CoreLocation
import MapKit

// MARK: - Coordinate Helper
struct CodableCoordinate: Codable {
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
struct RouteSegment: Codable, Identifiable {
    let id: UUID
    let coordinates: [CodableCoordinate]
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.id = UUID()
        self.coordinates = coordinates.map(CodableCoordinate.init)
    }
    
    var path: [CLLocationCoordinate2D] {
        coordinates.map(\.coordinate)
    }
}

// MARK: - Virtual Route
struct VirtualRoute: Identifiable, Codable {
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
    
    var fullPath: [CLLocationCoordinate2D] {
        segments.flatMap { $0.path }
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
        self.milestones = milestones.map { milestone in
            RouteMilestone(
                id: milestone.id,
                routeId: id,
                name: milestone.name,
                description: milestone.description,
                distanceFromStart: milestone.distanceFromStart,
                imageName: milestone.imageName
            )
        }
        self.imageName = imageName
        self.region = region
        self.codableStartCoordinate = CodableCoordinate(coordinate: startCoordinate)
        self.codableWaypoints = waypoints.map(CodableCoordinate.init)
        self.segments = segments
    }
    
    func coordinate(at distance: Double) -> CLLocationCoordinate2D? {
        var accumulatedDistance: Double = 0
        
        for segment in segments {
            let coordinates = segment.path
            for i in 0..<(coordinates.count - 1) {
                let start = coordinates[i]
                let end = coordinates[i + 1]
                let segmentDistance = CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
                
                if accumulatedDistance + segmentDistance > distance {
                    let remainingDistance = distance - accumulatedDistance
                    let fraction = remainingDistance / segmentDistance
                    return interpolateCoordinate(from: start, to: end, fraction: fraction)
                }
                
                accumulatedDistance += segmentDistance
            }
        }
        
        return segments.last?.path.last
    }
    
    private func interpolateCoordinate(from start: CLLocationCoordinate2D,
                                     to end: CLLocationCoordinate2D,
                                     fraction: Double) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * fraction
        let lon = start.longitude + (end.longitude - start.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Route Milestone
struct RouteMilestone: Identifiable, Codable {
    let id: UUID
    let routeId: UUID
    let name: String
    let description: String
    let distanceFromStart: Double
    let imageName: String
    
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
}

// MARK: - Route Progress
struct RouteProgress: Codable {
    let id: UUID
    let routeId: UUID
    private(set) var startDate: Date
    private(set) var completedDistance: Double
    private(set) var lastUpdated: Date
    private(set) var completedMilestones: Set<UUID>
    let totalDistance: Double
    private(set) var dailyProgress: [String: Double]
    private(set) var isCompleted: Bool
    private(set) var completionDate: Date?
    
    struct DailyProgress: Codable {
        let date: Date
        var distance: Double
    }
    
    var percentageCompleted: Double {
        (completedDistance / (totalDistance / 1000)) * 100
    }
    
    var currentRoute: VirtualRoute? {
        RouteManager.shared.getRoute(by: routeId)
    }
    
    var completedPath: [CLLocationCoordinate2D] {
        guard let route = currentRoute else { return [] }
        guard completedDistance > 0 else { return [] }
        
        let distanceInMeters = completedDistance * 1000 // Convert km to meters
        return route.fullPath.prefix { coordinate in
            let startCoord = route.startCoordinate
            let location1 = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
            let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return location1.distance(from: location2) <= distanceInMeters
        }
    }
    
    init(id: UUID = UUID(),
         routeId: UUID,
         startDate: Date,
         completedDistance: Double = 0,
         lastUpdated: Date,
         completedMilestones: Set<UUID> = [],
         totalDistance: Double,
         dailyProgress: [String: Double] = [:],
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
        self.isCompleted = isCompleted
        self.completionDate = completionDate
    }
    
    mutating func updateProgress(distance: Double, date: Date) {
        completedDistance += distance
        lastUpdated = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        dailyProgress[dateString, default: 0] += distance
        
        if completedDistance >= totalDistance && !isCompleted {
            isCompleted = true
            completionDate = date
        }
    }
    
    mutating func updateDailyProgress(distance: Double, for date: String) {
        dailyProgress[date] = distance
    }
    
    mutating func updateCompletedDistance(_ distance: Double, isManual: Bool) {
        completedDistance = isManual ? distance : max(distance, completedDistance)
        lastUpdated = Date()
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completionDate = Date()
    }
    
    mutating func addCompletedMilestone(_ id: UUID) {
        completedMilestones.insert(id)
    }
    
    var dailyProgressArray: [DailyProgress] {
        dailyProgress.compactMap { dateString, distance in
            guard let date = Self.dateFormatter.date(from: dateString) else { return nil }
            return DailyProgress(date: date, distance: distance)
        }.sorted { $0.date < $1.date }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
