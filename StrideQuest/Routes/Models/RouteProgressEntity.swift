//
//  RouteProgressEntity.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-29.
//

import CoreData

@objc(RouteProgressEntity)
public class RouteProgressEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var routeId: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var totalDistance: Double
    @NSManaged public var completedDistance: Double
    @NSManaged public var lastUpdated: Date
    @NSManaged public var completedMilestonesData: Data
    @NSManaged public var dailyProgressData: Data
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completionDate: Date?
    
}

// Move extension methods to a separate extension
extension RouteProgressEntity {
    func toModel() throws -> RouteProgress {
        let decoder = JSONDecoder()
        let dailyProgress = try decoder.decode([RouteProgress.DailyProgress].self, from: dailyProgressData)
        let completedMilestones = try decoder.decode(Set<UUID>.self, from: completedMilestonesData)
        
        return RouteProgress(
            id: id,
            routeId: routeId,
            startDate: startDate,
            completedDistance: completedDistance,
            lastUpdated: lastUpdated,
            completedMilestones: completedMilestones,
            totalDistance: totalDistance,
            dailyProgress: dailyProgress,
            isCompleted: isCompleted,
            completionDate: completionDate
        )
    }
    
    func update(with model: RouteProgress) throws {
        let encoder = JSONEncoder()
        
        self.id = model.id
        self.routeId = model.routeId
        self.startDate = model.startDate
        self.totalDistance = model.totalDistance
        self.completedDistance = model.completedDistance
        self.lastUpdated = model.lastUpdated
        self.isCompleted = model.isCompleted
        self.completionDate = model.completionDate
        self.completedMilestonesData = try encoder.encode(model.completedMilestones)
        self.dailyProgressData = try encoder.encode(model.dailyProgress)
    }
}
