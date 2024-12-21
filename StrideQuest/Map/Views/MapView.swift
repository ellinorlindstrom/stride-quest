import SwiftUI
import MapKit
import Combine

struct MapView: View {
    @EnvironmentObject var routeManager: RouteManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isUserInteracting = false
    @State private var mapStyle = MapStyle.standard(elevation: .realistic)
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: .all) {
                if let route = routeManager.currentRoute {
                    // Route polyline
                    MapPolyline(coordinates: route.path)
                        .stroke(.textSq.opacity(0.8), lineWidth: 4)
                    
                    // Progress polyline
                    if !routeManager.progressPolyline.isEmpty {
                        MapPolyline(coordinates: routeManager.progressPolyline)
                            .stroke(.accentSq, lineWidth: 4)
                    }
                    
                    // Current position annotation
                    if let currentPosition = routeManager.progressPolyline.last ?? route.segments.first?.path.first {
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
                                            routeManager.selectedMilestone = milestone
                                            withAnimation {
                                                routeManager.showMilestoneCard = true
                                            }
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
            
            ConfettiView(isShowing: $routeManager.showConfetti)
            
            if routeManager.showMilestoneCard,
               let milestone = routeManager.selectedMilestone,
               let routeId = routeManager.currentRoute?.id {
                MilestoneCard(
                    milestone: milestone,
                    routeId: routeId,
                    isShowing: $routeManager.showMilestoneCard,
                    selectedMilestone: $routeManager.selectedMilestone
                )
                .padding()
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
            
            if isLoading {
                LoadingView()
                    .zIndex(100)
            }
        }
        
        .onChange(of: routeManager.showMilestoneCard) { oldValue, newValue in
            if !newValue {
                routeManager.selectedMilestone = nil
            }
        }
        .onAppear {
                    isLoading = true
                    focusOnRoute()
                }
                .onReceive(routeManager.$currentRoute) { _ in
                    isLoading = true
                    focusOnRoute()
                }
        
        .onReceive(routeManager.$currentProgress) { _ in
            routeManager.updateProgressPolyline()
        }
    }
    
    private func focusOnRoute() {
            if let route = routeManager.currentRoute {
                let span = MKCoordinateSpan(
                    latitudeDelta: 0.2,
                    longitudeDelta: 0.2
                )
                
                let region = MKCoordinateRegion(
                    center: route.startCoordinate,
                    span: span
                )
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(region)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
        }
    }

//    private func setInitialCamera() {
//        if let route = routeManager.currentRoute {
//            let span = MKCoordinateSpan(
//                latitudeDelta: routeManager.isActivelyTracking ? 0.05 : 0.2,
//                longitudeDelta: routeManager.isActivelyTracking ? 0.05 : 0.2
//            )
//            
//            // If actively tracking, center on current position instead of route start
//            let center = routeManager.progressPolyline.last ?? route.startCoordinate
//            
//            let region = MKCoordinateRegion(
//                center: center,
//                span: span
//            )
//            
//            // Set camera position with animation
//            withAnimation(.easeInOut(duration: 0.5)) {
//                cameraPosition = .region(region)
//            }
//            
//            // Add delay before hiding loading screen
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    isLoading = false
//                }
//            }
//        } else {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    isLoading = false
//                }
//            }
//        }
//    }
//}
