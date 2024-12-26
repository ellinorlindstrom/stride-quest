import Foundation
import CoreLocation
import MapKit

struct RouteUtils {
    
    enum RetryConfig {
            static let maxAttempts = 3
            static let baseDelay: TimeInterval = 1.0 // Base delay in seconds
        }
    
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
            return nil
        }
        
        let lat = start.latitude + (end.latitude - start.latitude) * clampedFraction
        let lon = start.longitude + (end.longitude - start.longitude) * clampedFraction
        
        let interpolated = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        // Verify the interpolated coordinate is valid
        guard CLLocationCoordinate2DIsValid(interpolated) else {
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
            
            var lastError: Error?
            
            for attempt in 1...RetryConfig.maxAttempts {
                do {
                    let request = MKDirections.Request()
                    request.transportType = .walking
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
                    
                    let directions = MKDirections(request: request)
                    
                    // Add exponential backoff delay for retries
                    if attempt > 1 {
                        let delay = RetryConfig.baseDelay * pow(2.0, Double(attempt - 2))
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                    
                    let response = try await directions.calculate()
                    
                    guard let route = response.routes.first else {
                        throw RouteError.noRouteFound
                    }
                    
                    return RouteSegment(coordinates: route.polyline.coordinates)
                    
                } catch {
                    lastError = error
                    
                    // Log the error with attempt number
                    print("🚨 Attempt \(attempt) failed: \(error.localizedDescription)")
                    
                    // If this was the last attempt, throw the error
                    if attempt == RetryConfig.maxAttempts {
                        throw RouteError.maxRetriesExceeded(underlyingError: lastError)
                    }
                }
            }
            
            // This should never be reached due to the throw in the loop
            throw RouteError.maxRetriesExceeded(underlyingError: lastError)
        }
    }


extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
