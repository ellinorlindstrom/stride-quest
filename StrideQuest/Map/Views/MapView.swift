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
    @State private var selectedMilestone: RouteMilestone?
    @State private var showMilestoneCard = false
    
    var body: some View {
        ZStack {
            if let progress = routeManager.currentProgress,
               let route = progress.currentRoute {
                MapContentView(
                    cameraPosition: $cameraPosition,
                    route: route,
                    progressPolyline: progressPolyline,
                    currentPosition: progressPolyline.last ?? routeManager.currentRouteCoordinate,
                    routeManager: routeManager,
                    onMilestoneSelected: { milestone in
                        print("📍 Milestone tapped: \(milestone.name)")
                        print("📍 Current selectedMilestone before update: \(String(describing: selectedMilestone))")
                        
                        // Route ID check
                        if milestone.routeId == route.id {
                            selectedMilestone = milestone
                            print("📍 selectedMilestone updated to: \(String(describing: selectedMilestone))")
                            
                            withAnimation {
                                showMilestoneCard = true
                            }
                            print("📍 showMilestoneCard set to: \(showMilestoneCard)")
                        } else {
                            print("🚫 Milestone routeId does not match current routeId.")
                        }
                    }
                    
                )
                .gesture(
                    SimultaneousGesture(
                        DragGesture().onChanged { _ in isUserInteracting = true },
                        MagnificationGesture().onChanged { _ in isUserInteracting = true }
                    )
                )
            } else {
                Map(position: $cameraPosition) {
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapPitchToggle()
                    MapCompass()
                    MapScaleView()
                }
            }
            
            ConfettiView(isShowing: $showConfetti)
            
            if showMilestoneCard, let milestone = selectedMilestone {
                MilestoneDetailCard(
                    milestone: milestone,
                    routeId: routeManager.currentProgress?.currentRoute?.id ?? UUID(),
                    isShowing: $showMilestoneCard,
                    selectedMilestone: $selectedMilestone
                )
                .padding()
                .transition(.move(edge: .bottom))
                .zIndex(2)            }
        }
        .onChange(of: showMilestoneCard) { oldValue, newValue in
            print("🎭 showMilestoneCard changed from \(oldValue) to \(newValue)")
            if let milestone = selectedMilestone {
                print("🎭 Selected milestone: \(milestone.name)")
            }
        }
        .onAppear {
            setInitialCamera()
        }
        .onReceive(routeManager.$currentProgress) { _ in
            setInitialCamera()
            updateProgressPolyline()
        }
        .onReceive(routeManager.$currentMapRegion) { region in
            if let region = region, !isUserInteracting {
                cameraPosition = .region(region)
            }
        }
        .onReceive(routeManager.milestoneCompletedPublisher) { milestone in
            print("🎉 Milestone completed: \(milestone.name), routeId: \(milestone.routeId)")
            if let currentRouteId = routeManager.currentProgress?.currentRoute?.id,
               milestone.routeId == currentRouteId {
                print("🎯 Showing card for milestone: \(milestone.name)")
                selectedMilestone = milestone
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMilestoneCard = true
                    showConfetti = true
                }
            } else {
                print("🚫 Milestone routeId does not match current routeId.")
            }
        }
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
            progressPolyline = route.waypoints
            return
        }
        
        let coordinates = route.waypoints
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


