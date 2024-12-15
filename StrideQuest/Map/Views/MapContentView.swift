import SwiftUI
import MapKit

struct MapContentView: View {
    @Binding var cameraPosition: MapCameraPosition
    let route: VirtualRoute
    let currentPosition: CLLocationCoordinate2D?
    let routeManager: RouteManager
    let onMilestoneSelected: (RouteMilestone) -> Void
    @State private var snappedPathToCurrentPosition: [CLLocationCoordinate2D] = []

    
    var body: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            // Route polyline
            MapPolyline(coordinates: route.fullPath)
                .stroke(.yellow, lineWidth: 3)
            
            // Progress polyline including current position
                        if let progress = routeManager.currentProgress,
                           let currentPosition = currentPosition {
                            let completedCoordinates = progress.completedPath + [currentPosition]
                            MapPolyline(coordinates: completedCoordinates)
                                .stroke(.purple, lineWidth: 3)
                        }
            
            // Milestone annotations
            ForEach(route.milestones) { milestone in
                let coordinate = route.coordinate(at: milestone.distanceFromStart) ?? route.startCoordinate
                Annotation(milestone.name, coordinate: coordinate) {
                    MilestoneAnnotationView(
                        milestone: milestone,
                        coordinate: coordinate,
                        isCompleted: routeManager.isMilestoneCompleted(milestone),
                        onTap: {
                            if routeManager.isMilestoneCompleted(milestone) {
                                onMilestoneSelected(milestone)
                            }
                        },
                        currentRouteId: route.id
                    )
                }
            }
            // Current position annotation
            if let currentPosition = currentPosition {
                Annotation("Current Position", coordinate: currentPosition) {
                    CurrentPositionView(coordinate: currentPosition)
                }
            }
        }
        .mapControls {
            MapPitchToggle()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
