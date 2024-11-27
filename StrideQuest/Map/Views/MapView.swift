import SwiftUI
import MapKit



struct MapView: View {
    @Binding var position: MapCameraPosition
    @ObservedObject var routeManager = RouteManager.shared

    var body: some View {
        Map(position: $position) {
            if let routePosition = routeManager.currentRouteCoordinate {
                Marker("Current Position", coordinate: routePosition)
                    .tint(.blue)
            } else {
                UserAnnotation()
            }
            
            if let progress = routeManager.currentProgress,
               let route = progress.currentRoute {
                ForEach(route.milestones) { milestone in
                    if let coordinate = getCoordinate(for: milestone, in: route) {
                        Marker(milestone.name, coordinate: coordinate)
                            .tint(progress.completedMilestones.contains(milestone.id) ? .green : .red)
                    }
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
          }
          
          private func getCoordinate(for milestone: RouteMilestone, in route: VirtualRoute) -> CLLocationCoordinate2D? {
              // Calculate milestone position based on distance along route
              let progress = milestone.distanceFromStart / route.totalDistance
              let index = Int(floor(Double(route.coordinates.count) * progress))
              return index < route.coordinates.count ? route.coordinates[index] : nil
          }
       }
