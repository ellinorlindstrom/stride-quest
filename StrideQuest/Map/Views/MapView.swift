import SwiftUI
import MapKit



struct MapView: View {
    @Binding var position: MapCameraPosition
    @ObservedObject var routeManager = RouteManager.shared
    @State private var progressPolyline: [CLLocationCoordinate2D] = []
    
    
    var body: some View {
        Map(position: $position) {
            if let routePosition = routeManager.currentRouteCoordinate {
                MapCircle(center: routePosition, radius: 50)
                    .foregroundStyle(.blue.opacity(0.3))
                    .stroke(.white, lineWidth: 2)
            } else {
                UserAnnotation()
            }
            
            if let progress = routeManager.currentProgress,
               let route = progress.currentRoute {
                // Full route polyline
                MapPolyline(coordinates: route.coordinates)
                    .stroke(.gray, lineWidth: 3)
                
                // Progress polyline
                MapPolyline(coordinates: progressPolyline)
                    .stroke(.blue, lineWidth: 3)
                
                // Milestone markers
                ForEach(route.milestones) { milestone in
                    let coordinate = getMilestoneCoordinate(milestone: milestone, coordinates: route.coordinates)
                    Marker(milestone.name, coordinate: coordinate)
                        .tint(progress.completedMilestones.contains(milestone.id) ? .green : .red)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapPitchToggle()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
        .onReceive(routeManager.$currentMapRegion) { region in
            if let region = region {
                position = .region(region)
            }
        }
        .onReceive(routeManager.$currentProgress) { progress in
            updateProgressPolyline()
        }
    }
    
    private func getMilestoneCoordinate(milestone: RouteMilestone, coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        // Convert both to kilometers
        let milestoneDistanceKm = milestone.distanceFromStart / 1000
        let routeTotalKm = routeManager.currentProgress!.currentRoute!.totalDistance / 1000
        let progress = milestoneDistanceKm / routeTotalKm
        let index = Int(floor(Double(coordinates.count - 1) * progress))
        return coordinates[index]
    }
    
    private func updateProgressPolyline() {
        guard let progress = routeManager.currentProgress,
              let route = progress.currentRoute else {
            progressPolyline = []
            return
        }
        
        let routeTotalKm = route.totalDistance / 1000
        let percentComplete = progress.completedDistance / routeTotalKm
        
        // Early exit if no real progress
        if percentComplete <= 0 {
            progressPolyline = []
            return
        }
        
        // If complete, show full route
        if percentComplete >= 1 {
            progressPolyline = route.coordinates
            return
        }
        
        let coordinates = route.coordinates
        
        // Need at least 2 points to create a line
        guard coordinates.count >= 2 else {
            progressPolyline = []
            return
        }
        
        // Calculate cumulative distances between points
        var cumulativeDistances: [Double] = [0]
        var totalDistance: Double = 0
        
        for i in 1..<coordinates.count {
            let previous = coordinates[i-1]
            let current = coordinates[i]
            let segmentDistance = calculateDistance(from: previous, to: current)
            totalDistance += segmentDistance
            cumulativeDistances.append(totalDistance)
        }
        
        // Scale to match route's actual distance
        let scaleFactor = route.totalDistance / totalDistance
        cumulativeDistances = cumulativeDistances.map { $0 * scaleFactor }
        
        // Find how far we've traveled in meters
        let targetDistance = progress.completedDistance * 1000 // convert km to meters
        
        // Find the last point we've reached
        var lastPointIndex = 0
        for (index, distance) in cumulativeDistances.enumerated() {
            if distance > targetDistance {
                lastPointIndex = index
                break
            }
        }
        
        // If we're between points, interpolate the exact position
        if lastPointIndex > 0 {
            let previousDistance = cumulativeDistances[lastPointIndex - 1]
            let nextDistance = cumulativeDistances[lastPointIndex]
            let fraction = (targetDistance - previousDistance) / (nextDistance - previousDistance)
            
            let start = coordinates[lastPointIndex - 1]
            let end = coordinates[lastPointIndex]
            let interpolatedLat = start.latitude + (end.latitude - start.latitude) * fraction
            let interpolatedLon = start.longitude + (end.longitude - start.longitude) * fraction
            
            var result = Array(coordinates[0..<lastPointIndex])
            result.append(CLLocationCoordinate2D(latitude: interpolatedLat, longitude: interpolatedLon))
            progressPolyline = result
        } else {
            progressPolyline = [coordinates[0]]
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}
