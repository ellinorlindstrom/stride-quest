import SwiftUI
import MapKit
import Combine

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isUserInteracting = false
    @ObservedObject var routeManager = RouteManager.shared
    @State private var progressPolyline: [CLLocationCoordinate2D] = []
    @State private var mapStyle = MapStyle.standard(elevation: .realistic)
    @State private var showConfetti = false

    
    var body: some View {
        ZStack {  // Add ZStack here
            Map(position: $cameraPosition, interactionModes: .all) {
                if let progress = routeManager.currentProgress,
                   let route = progress.currentRoute {
                    MapPolyline(coordinates: route.coordinates)
                        .stroke(.gray, lineWidth: 3)
                    
                    MapPolyline(coordinates: progressPolyline)
                        .stroke(.blue, lineWidth: 3)
                    
                    ForEach(route.milestones) { milestone in
                        let coordinate = getMilestoneCoordinate(milestone: milestone, coordinates: route.coordinates)
                        Marker(milestone.name, coordinate: coordinate)
                            .tint(routeManager.isMilestoneCompleted(milestone) ? .green : .gray)
                    }
                    
                    if let currentPosition = progressPolyline.last ?? routeManager.currentRouteCoordinate {
                        Annotation("", coordinate: currentPosition) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 15, height: 15)
                                    .overlay(Circle().stroke(.white, lineWidth: 3))
                            }
                        }
                    }
                }
            }
            .onAppear {
                setInitialCamera()
            }
            .onReceive(routeManager.$currentProgress) { _ in
                setInitialCamera()
            }
            .mapControls {
                MapPitchToggle()
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .gesture(
                SimultaneousGesture(
                    DragGesture().onChanged { _ in isUserInteracting = true },
                    MagnificationGesture().onChanged { _ in isUserInteracting = true }
                )
            )
            .onReceive(routeManager.$currentMapRegion) { region in
                if let region = region, !isUserInteracting {
                    cameraPosition = .region(region)
                }
            }
            .onReceive(routeManager.$currentProgress) { _ in
                updateProgressPolyline()
            }
            .onReceive(routeManager.milestoneCompletedPublisher) { milestone in
                withAnimation {
                    showConfetti = true
                }
            }
            
            // Add ConfettiView on top of the Map
            ConfettiView(isShowing: $showConfetti)
        }
    }
            
    
    
    private func getMilestoneCoordinate(milestone: RouteMilestone, coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let milestoneDistance = milestone.distanceFromStart
        var currentDistance: Double = 0
        
        for i in 1..<coordinates.count {
            let previous = coordinates[i-1]
            let current = coordinates[i]
            let segmentDistance = calculateDistance(from: previous, to: current)
            
            if currentDistance + segmentDistance >= milestoneDistance {
                // Interpolate position within this segment
                let remainingDistance = milestoneDistance - currentDistance
                let fraction = remainingDistance / segmentDistance
                
                let lat = previous.latitude + (current.latitude - previous.latitude) * fraction
                let lon = previous.longitude + (current.longitude - previous.longitude) * fraction
                
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            currentDistance += segmentDistance
        }
        
        return coordinates[0] 
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    private func updateProgressPolyline() {
        guard let progress = routeManager.currentProgress,
              let route = progress.currentRoute else {
            progressPolyline = []
            return
        }
        
        let routeTotalKm = route.totalDistance / 1000
        let percentComplete = progress.completedDistance / routeTotalKm
        
        if percentComplete <= 0 {
            progressPolyline = []
            return
        }
        
        if percentComplete >= 1 {
            progressPolyline = route.coordinates
            return
        }
        
        let coordinates = route.coordinates
        guard coordinates.count >= 2 else {
            progressPolyline = []
            return
        }
        
        var cumulativeDistances: [Double] = [0]
        var totalDistance: Double = 0
        
        // Calculate cumulative distances between coordinates
        for i in 1..<coordinates.count {
            let previous = coordinates[i-1]
            let current = coordinates[i]
            let segmentDistance = calculateDistance(from: previous, to: current)
            totalDistance += segmentDistance
            cumulativeDistances.append(totalDistance)
        }
        
        // Scale distances to match route's total distance
        let scaleFactor = route.totalDistance / totalDistance
        cumulativeDistances = cumulativeDistances.map { $0 * scaleFactor }
        
        let targetDistance = progress.completedDistance * 1000 // Convert to meters
        
        // Find the last point we've passed
        var lastPointIndex = 0
        for (index, distance) in cumulativeDistances.enumerated() {
            if distance > targetDistance {
                lastPointIndex = index
                break
            }
        }
        
        if lastPointIndex > 0 {
            // Interpolate between the last two points
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
    
    private func setInitialCamera() {
        if let route = routeManager.currentProgress?.currentRoute {
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            cameraPosition = .region(MKCoordinateRegion(
                center: route.startCoordinate,
                span: span
            ))
        }
    }
}


