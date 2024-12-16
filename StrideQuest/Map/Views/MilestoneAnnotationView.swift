import SwiftUI
import MapKit

struct MilestoneAnnotationView: View {
    @ObservedObject private var routeManager = RouteManager.shared
    let milestone: RouteMilestone
    let coordinate: CLLocationCoordinate2D
    let isCompleted: Bool
    let onTap: () -> Void
    let currentRouteId: UUID  
    
    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .foregroundStyle(routeManager.isMilestoneCompleted(milestone) ? Color.green : Color.gray)
            .font(.title)
            .onTapGesture {
                print("🎯 Milestone tapped: \(milestone.name)")
                print("🎯 Is completed: \(isCompleted)")
                // Only call onTap if this milestone belongs to current route
                if milestone.routeId == currentRouteId {
                    onTap()
                }
            }
    }
}



