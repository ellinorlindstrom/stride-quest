import SwiftUI
import MapKit

struct MapContentView: View {
    @Binding var cameraPosition: MapCameraPosition
    let route: VirtualRoute
    let progressPolyline: [CLLocationCoordinate2D]
    let currentPosition: CLLocationCoordinate2D?
    let routeManager: RouteManager
    let onMilestoneSelected: (RouteMilestone) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            // Route polyline
            MapPolyline(coordinates: route.coordinates)
                .stroke(.gray, lineWidth: 3)

            // Progress polyline
            MapPolyline(coordinates: progressPolyline)
                .stroke(.blue, lineWidth: 3)

            // Milestone annotations
            ForEach(route.milestones) { milestone in
                let coordinate = getMilestoneCoordinate(milestone: milestone, coordinates: route.coordinates)
                Annotation(milestone.name, coordinate: coordinate) {
                    MilestoneAnnotationView(
                        milestone: milestone,
                        coordinate: coordinate,
                        isCompleted: routeManager.isMilestoneCompleted(milestone),
                        onTap: {
                            if routeManager.isMilestoneCompleted(milestone) &&
                                milestone.routeId == routeManager.currentProgress?.currentRoute?.id {
                                onMilestoneSelected(milestone)
                            }
                        }
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
