import CoreLocation
import Foundation

extension VirtualRoute {
    static func calculateActualDistance(coordinates: [CLLocationCoordinate2D]) -> Double {
        var totalDistance: Double = 0
        for i in 1..<coordinates.count {
            let prev = coordinates[i-1]
            let curr = coordinates[i]
            let from = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let to = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            totalDistance += from.distance(from: to)
        }
        return totalDistance
    }
    
    static func findCoordinatesForDistance(coordinates: [CLLocationCoordinate2D], targetDistance: Double) -> [CLLocationCoordinate2D] {
        var trimmedCoordinates: [CLLocationCoordinate2D] = [coordinates[0]]
        var currentDistance: Double = 0
        
        for i in 1..<coordinates.count {
            let prev = coordinates[i-1]
            let curr = coordinates[i]
            let from = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let to = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            let segmentDistance = from.distance(from: to)
            
            if currentDistance + segmentDistance > targetDistance {
                // Interpolate final point
                let remainingDistance = targetDistance - currentDistance
                let fraction = remainingDistance / segmentDistance
                let newLat = prev.latitude + (curr.latitude - prev.latitude) * fraction
                let newLon = prev.longitude + (curr.longitude - prev.longitude) * fraction
                trimmedCoordinates.append(CLLocationCoordinate2D(latitude: newLat, longitude: newLon))
                break
            }
            
            currentDistance += segmentDistance
            trimmedCoordinates.append(curr)
        }
        
        return trimmedCoordinates
    }
}
