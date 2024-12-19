import SwiftUI
import MapKit

struct MilestoneAnnotationView: View {
    
    @EnvironmentObject var routeManager: RouteManager
    let milestone: RouteMilestone
    let coordinate: CLLocationCoordinate2D
    let isCompleted: Bool
    let onTap: () -> Void
    let currentRouteId: UUID  
    
    var body: some View {
        Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(routeManager.isMilestoneCompleted(milestone) ? Color.green : Color.gray)
                    .font(.title)
                    .onAppear {
                        print("🎯 MilestoneAnnotation appeared:")
                        print("  - Milestone: \(milestone.name)")
                        print("  - Is tracking: \(routeManager.isActivelyTracking)")
                        print("  - Is completed: \(routeManager.isMilestoneCompleted(milestone))")
                    }
                    .onTapGesture {
                        print("🎯 Milestone tapped: \(milestone.name)")
                        print("  - Is completed: \(isCompleted)")
                        print("  - Current route match: \(milestone.routeId == currentRouteId)")
                        if milestone.routeId == currentRouteId {
                            onTap()
                }
            }
    }
}



