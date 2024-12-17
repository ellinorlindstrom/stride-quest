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
            Map(position: $cameraPosition, interactionModes: .all) {
                if let progress = routeManager.currentProgress,
                   let route = progress.currentRoute {
                    // Route polyline
                    MapPolyline(coordinates: route.fullPath)
                        .stroke(.purple.opacity(0.4), lineWidth: 4)
                    
                    // Progress polyline
                    if !progressPolyline.isEmpty {
                        MapPolyline(coordinates: progressPolyline)
                            .stroke(.blue, lineWidth: 4)
                    }
                    
                    // Current position annotation
                    if let currentPosition = progressPolyline.last ?? route.segments.first?.path.first {
                        Annotation("Current Position", coordinate: currentPosition) {
                            CurrentPositionView(coordinate: currentPosition)
                        }
                    }
                    
                    // Milestone annotations
                    ForEach(route.milestones) { milestone in
                        if let coordinate = RouteUtils.findCoordinate(
                            distance: milestone.distanceFromStart,
                            in: route
                        ) {
                            Annotation(milestone.name, coordinate: coordinate) {
                                MilestoneAnnotationView(
                                    milestone: milestone,
                                    coordinate: coordinate,
                                    isCompleted: routeManager.isMilestoneCompleted(milestone),
                                    onTap: {
                                        if routeManager.isMilestoneCompleted(milestone) {
                                            handleMilestoneSelection(milestone, route: route)
                                        }
                                    },
                                    currentRouteId: route.id
                                )
                            }
                        }
                    }
                }
            }
            .mapStyle(mapStyle)
            .mapControls {
                MapPitchToggle()
                MapCompass()
                MapScaleView()
            }
            .gesture(
                SimultaneousGesture(
                    DragGesture().onChanged { _ in isUserInteracting = true },
                    MagnificationGesture().onChanged { _ in isUserInteracting = true }
                )
            )
            
            ConfettiView(isShowing: $showConfetti)
            
            if showMilestoneCard, let milestone = selectedMilestone {
                MilestoneCard(
                    milestone: milestone,
                    routeId: routeManager.currentProgress?.currentRoute?.id ?? UUID(),
                    isShowing: $showMilestoneCard,
                    selectedMilestone: $selectedMilestone
                )
                .padding()
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
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
            updateProgressPolyline()
        }
        .onReceive(routeManager.$currentMapRegion) { region in
            if let region = region, !isUserInteracting {
                cameraPosition = .region(region)
            }
        }
        .onReceive(routeManager.milestoneCompletedPublisher) { milestone in
            handleMilestoneCompletion(milestone)
        }
    }
    
    private func handleMilestoneSelection(_ milestone: RouteMilestone, route: VirtualRoute) {
        print("📍 Milestone tapped: \(milestone.name)")
        print("📍 Current selectedMilestone before update: \(String(describing: selectedMilestone))")
        
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
    
    private func handleMilestoneCompletion(_ milestone: RouteMilestone) {
        if let currentRouteId = routeManager.currentProgress?.currentRoute?.id,
           milestone.routeId == currentRouteId {
            selectedMilestone = milestone
            withAnimation(.easeInOut(duration: 0.3)) {
                showMilestoneCard = true
                showConfetti = true
            }
        } else {
            print("🚫 Milestone routeId does not match current routeId.")
        }
    }
    
    private func updateProgressPolyline() {
        guard let progress = routeManager.currentProgress,
              let route = progress.currentRoute else {
            progressPolyline = []
            return
        }
        
        var coordinates: [CLLocationCoordinate2D] = []
        var accumulatedDistance: Double = 0
        let targetDistance = progress.completedDistance
        
        print("⚡️ Updating progress polyline")
        print("Total completed distance: \(targetDistance) km")
        
        // Always start with the first coordinate
        if let firstCoord = route.segments.first?.path.first {
            coordinates.append(firstCoord)
        }
        
        // Early exit if we haven't moved from start
        guard targetDistance > 0 else {
            progressPolyline = coordinates
            return
        }
        
        outerLoop: for segment in route.segments {
            let segmentCoordinates = segment.path
            
            for i in 0..<(segmentCoordinates.count - 1) {
                let start = segmentCoordinates[i]
                let end = segmentCoordinates[i + 1]
                let pointDistance = RouteUtils.calculateDistance(from: start, to: end)
                
                if accumulatedDistance + pointDistance >= targetDistance {
                    // We've found the segment containing our target distance
                    let remainingDistance = targetDistance - accumulatedDistance
                    let fraction = min(1.0, max(0.0, remainingDistance / pointDistance))
                    
                    if let interpolated = RouteUtils.interpolateCoordinate(from: start, to: end, fraction: fraction) {
                        coordinates.append(interpolated)
                    }
                    break outerLoop // Exit both loops once we've found our target point
                }
                
                coordinates.append(end)
                accumulatedDistance += pointDistance
            }
        }
        
        progressPolyline = coordinates
        print("Final polyline has \(coordinates.count) coordinates")
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


