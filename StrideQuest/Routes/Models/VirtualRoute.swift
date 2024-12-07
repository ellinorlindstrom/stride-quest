import Foundation
import CoreLocation

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

struct VirtualRoute: Identifiable, Codable {
   let id: UUID
   let name: String
   let description: String
   let totalDistance: Double // in meters
   let milestones: [RouteMilestone]
   let imageName: String
   let region: String
   private let codableStartCoordinate: CodableCoordinate
   private let codableCoordinates: [CodableCoordinate]
   
   var startCoordinate: CLLocationCoordinate2D { codableStartCoordinate.coordinate }
   var coordinates: [CLLocationCoordinate2D] { codableCoordinates.map(\.coordinate) }
   
   init(id: UUID = UUID(),
        name: String,
        description: String,
        totalDistance: Double,
        milestones: [RouteMilestone],
        imageName: String,
        region: String,
        startCoordinate: CLLocationCoordinate2D,
        coordinates: [CLLocationCoordinate2D]) {
       self.id = id
       self.name = name
       self.description = description
       self.totalDistance = totalDistance
       self.milestones = milestones
       self.imageName = imageName
       self.region = region
       self.codableStartCoordinate = CodableCoordinate(coordinate: startCoordinate)
       self.codableCoordinates = coordinates.map(CodableCoordinate.init)
   }
}

struct RouteMilestone: Identifiable, Codable {
   let id: UUID
   let name: String
   let description: String
   let distanceFromStart: Double // in meters
   let imageName: String
   
   init(id: UUID = UUID(),
        name: String,
        description: String,
        distanceFromStart: Double,
        imageName: String) {
       self.id = id
       self.name = name
       self.description = description
       self.distanceFromStart = distanceFromStart
       self.imageName = imageName
   }
}
    

