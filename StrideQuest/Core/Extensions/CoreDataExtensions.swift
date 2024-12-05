//
//  CoreDataExtensions.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-03.
//

import CoreData
import Foundation
import HealthKit

// Move the RouteProgressEntity extension here
extension RouteProgressEntity {
    static func create(in context: NSManagedObjectContext,
                      completedDistance: Double,
                      routeId: UUID,
                      startDate: Date) -> RouteProgressEntity {
        let entity = RouteProgressEntity(context: context)
        entity.id = UUID()
        entity.routeId = routeId
        entity.startDate = startDate
        entity.completedDistance = completedDistance
        entity.lastUpdated = Date()
        entity.totalDistance = 0
        return entity
    }
}
