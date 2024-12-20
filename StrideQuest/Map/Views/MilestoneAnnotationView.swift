import SwiftUI
import MapKit

struct MilestoneAnnotationView: View {
    
    @EnvironmentObject var routeManager: RouteManager
    let milestone: RouteMilestone
    let coordinate: CLLocationCoordinate2D
    let isCompleted: Bool
    let onTap: () -> Void
    let currentRouteId: UUID
    
    private var shouldShowCompleted: Bool {
        if let progress = routeManager.currentProgress {
            // Show completed if:
            // 1. The milestone is explicitly marked as completed
            // 2. The current progress distance is beyond this milestone
            return progress.completedMilestones.contains(milestone.id) ||
            milestone.distanceFromStart <= progress.completedDistance
        }
        return false
    }
    
    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .foregroundStyle(shouldShowCompleted ? .green : .gray)
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


