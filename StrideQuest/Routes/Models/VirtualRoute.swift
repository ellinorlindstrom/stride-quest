//import Foundation
//import CoreLocation
//
//struct CodableCoordinate: Codable {
//    let latitude: Double
//    let longitude: Double
//    
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//    
//    init(coordinate: CLLocationCoordinate2D) {
//        self.latitude = coordinate.latitude
//        self.longitude = coordinate.longitude
//    }
//}
//
//struct VirtualRoute: Identifiable, Codable {
//    let id: UUID
//    let name: String
//    let description: String
//    let totalDistance: Double
//    let milestones: [RouteMilestone]
//    let imageName: String
//    let region: String
//    private let codableStartCoordinate: CodableCoordinate
//    private let codableCoordinates: [CodableCoordinate]
//    
//    var startCoordinate: CLLocationCoordinate2D { codableStartCoordinate.coordinate }
//    var coordinates: [CLLocationCoordinate2D] { codableCoordinates.map(\.coordinate) }
//    
//    init(id: UUID = UUID(),
//         name: String,
//         description: String,
//         totalDistance: Double,
//         milestones: [RouteMilestone],
//         imageName: String,
//         region: String,
//         startCoordinate: CLLocationCoordinate2D,
//         coordinates: [CLLocationCoordinate2D]) {
//        self.id = id
//        self.name = name
//        self.description = description
//        self.totalDistance = totalDistance
//        self.milestones = milestones.map { milestone in
//                RouteMilestone(
//                    id: milestone.id,
//                    routeId: id,
//                    name: milestone.name,
//                    description: milestone.description,
//                    distanceFromStart: milestone.distanceFromStart,
//                    imageName: milestone.imageName
//                )
//            }
//        self.imageName = imageName
//        self.region = region
//        self.codableStartCoordinate = CodableCoordinate(coordinate: startCoordinate)
//        self.codableCoordinates = coordinates.map(CodableCoordinate.init)
//    }
//}
//
//struct RouteMilestone: Identifiable, Codable {
//    let id: UUID
//    let routeId: UUID
//    let name: String
//    let description: String
//    let distanceFromStart: Double
//    let imageName: String
//    
//    init(id: UUID = UUID(),
//         routeId: UUID,
//         name: String,
//         description: String,
//         distanceFromStart: Double,
//         imageName: String) {
//        self.id = id
//        self.routeId = routeId
//        self.name = name
//        self.description = description
//        self.distanceFromStart = distanceFromStart
//        self.imageName = imageName
//    }
//}
//
//
import Foundation
import CoreLocation
import MapKit

// Helper struct for coordinates
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

// New struct for route segments
struct RouteSegment: Codable {
    let coordinates: [CodableCoordinate]
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates.map(CodableCoordinate.init)
    }
    
    var path: [CLLocationCoordinate2D] {
        coordinates.map(\.coordinate)
    }
}

// Modified VirtualRoute
struct VirtualRoute: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let totalDistance: Double
    let milestones: [RouteMilestone]
    let imageName: String
    let region: String
    private let codableStartCoordinate: CodableCoordinate
    private let codableWaypoints: [CodableCoordinate]  // Changed from coordinates to waypoints
    private let segments: [RouteSegment]  // Added segments
    
    var startCoordinate: CLLocationCoordinate2D { codableStartCoordinate.coordinate }
    var waypoints: [CLLocationCoordinate2D] { codableWaypoints.map(\.coordinate) }
    var routeSegments: [RouteSegment] { segments }
    
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
}

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
    
    
    
    // Add this initializer
    init(id: UUID,
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
    
    var percentageCompleted: Double {
        (completedDistance / (totalDistance / 1000)) * 100
    }
    
    var currentRoute: VirtualRoute? {
        RouteManager.shared.getRoute(by: routeId)
    }
    
    // Add mutating functions for updating progress
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
    
    mutating func completeMilestone(_ id: UUID) {
        completedMilestones.insert(id)
    }
    
    // Helper for date formatting
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Computed property to get daily progress as array
    var dailyProgressArray: [DailyProgress] {
        dailyProgress.compactMap { dateString, distance in
            guard let date = Self.dateFormatter.date(from: dateString) else { return nil }
            return DailyProgress(date: date, distance: distance)
        }.sorted { $0.date < $1.date }
    }
    
    init(id: UUID = UUID(),
         routeId: UUID,
         startDate: Date,
         totalDistance: Double) {
        self.id = id
        self.routeId = routeId
        self.startDate = startDate
        self.completedDistance = 0
        self.lastUpdated = startDate
        self.completedMilestones = []
        self.totalDistance = totalDistance
        self.dailyProgress = [:]
        self.isCompleted = false
        self.completionDate = nil
    }
}
