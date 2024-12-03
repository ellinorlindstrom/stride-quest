import Foundation

struct RouteProgress: Codable {
    let id: UUID
    let routeId: UUID
    var startDate: Date
    var completedDistance: Double
    var lastUpdated: Date
    var completedMilestones: Set<UUID>
    var totalDistance: Double
    var dailyProgress: [DailyProgress]
    var isCompleted: Bool
    var completionDate: Date?
    
    struct DailyProgress: Codable {
        let date: Date
        var distance: Double
    }
    
    var percentageCompleted: Double {
            guard let route = currentRoute else { return 0 }
            let routeTotalKm = route.totalDistance / 1000
            return (completedDistance / routeTotalKm) * 100
        }
    
    var currentRoute: VirtualRoute? {
        RouteManager.shared.getRoute(by: routeId)
    }
}
