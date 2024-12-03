import SwiftUI
import MapKit

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isUserInteracting = false
    @ObservedObject var routeManager = RouteManager.shared
    @State private var progressPolyline: [CLLocationCoordinate2D] = []
    @State private var mapStyle = MapStyle.standard(elevation: .realistic)

    
    var body: some View {
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
                               .tint(progress.completedMilestones.contains(milestone.id) ? .green : .red)
                       }
                       
                       if let currentPosition = progressPolyline.last {
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
    }
    
    private func getMilestoneCoordinate(milestone: RouteMilestone, coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
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
        
        for i in 1..<coordinates.count {
            let previous = coordinates[i-1]
            let current = coordinates[i]
            let segmentDistance = calculateDistance(from: previous, to: current)
            totalDistance += segmentDistance
            cumulativeDistances.append(totalDistance)
        }
        
        let scaleFactor = route.totalDistance / totalDistance
        cumulativeDistances = cumulativeDistances.map { $0 * scaleFactor }
        
        let targetDistance = progress.completedDistance * 1000
        
        var lastPointIndex = 0
        for (index, distance) in cumulativeDistances.enumerated() {
            if distance > targetDistance {
                lastPointIndex = index
                break
            }
        }
        
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
    
    private func setInitialCamera() {
        if let route = routeManager.currentProgress?.currentRoute {
            cameraPosition = .region(MKCoordinateRegion(
                center: route.startCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            ))
        }
    }
}


