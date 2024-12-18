import Foundation
import CoreLocation
import MapKit

struct RouteUtils {
    /// Finds the coordinate along a route for a given distance.
    static func findCoordinate(distance: Double, in route: VirtualRoute) -> CLLocationCoordinate2D? {
        var accumulatedDistance: Double = 0
        
        for segment in route.segments {
            let coordinates = segment.path
            
            for i in 0..<(coordinates.count - 1) {
                let start = coordinates[i]
                let end = coordinates[i + 1]
                let segmentDistance = calculateDistance(from: start, to: end)
                
                if accumulatedDistance + segmentDistance >= distance {
                    let remainingDistance = distance - accumulatedDistance
                    let fraction = min(1.0, max(0.0, remainingDistance / segmentDistance))
                    return interpolateCoordinate(from: start, to: end, fraction: fraction)
                }
                
                accumulatedDistance += segmentDistance
            }
        }
        
        // If we didn't find the exact point, return the last coordinate
        return route.segments.last?.path.last
    }
    
    /// Interpolates a coordinate between two points based on a fraction.
    static func interpolateCoordinate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D? {
        let clampedFraction = min(1.0, max(0.0, fraction))
        
        // Check for invalid coordinates
        guard CLLocationCoordinate2DIsValid(start) && CLLocationCoordinate2DIsValid(end) else {
            print("⚠️ Invalid coordinates detected")
            return nil
        }
        
        let lat = start.latitude + (end.latitude - start.latitude) * clampedFraction
        let lon = start.longitude + (end.longitude - start.longitude) * clampedFraction
        
        let interpolated = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        // Verify the interpolated coordinate is valid
        guard CLLocationCoordinate2DIsValid(interpolated) else {
            print("⚠️ Invalid interpolated coordinate")
            return nil
        }
        
        return interpolated
    }
    
    /// Calculates the distance between two coordinates.
    static func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) / 1000.0 // Convert to kilometers
    }
    
    static func createWalkingSegment(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> RouteSegment {
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(start), CLLocationCoordinate2DIsValid(end) else {
            throw RouteError.invalidCoordinate
        }
        
        let request = MKDirections.Request()
        request.transportType = .walking
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RouteError.noRouteFound
        }
        
        let coordinates = route.polyline.coordinates
        return RouteSegment(coordinates: coordinates)
        
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
