import XCTest
import CoreLocation
@testable import StrideQuest

final class RouteManagerTests: XCTestCase {
    func testSaveRoute() {
        // Arrange
        let routeManager = CustomRouteManager.shared
        routeManager.waypoints = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        ]
        routeManager.totalDistance = 1000.0 // Simulate total distance
        
        let name = "Test Route"
        let description = "A test route for unit testing"

        // Act
        let savedRoute = routeManager.saveRoute(name: name, description: description)

        // Assert
        XCTAssertEqual(savedRoute.name, name)
        XCTAssertEqual(savedRoute.description, description)
        XCTAssertEqual(savedRoute.coordinates.count, routeManager.waypoints.count)
        XCTAssertEqual(savedRoute.totalDistance, routeManager.totalDistance)

        for (index, coordinate) in savedRoute.coordinates.enumerated() {
            XCTAssertTrue(coordinate.isEqual(to: routeManager.waypoints[index]))
        }
    }
}
