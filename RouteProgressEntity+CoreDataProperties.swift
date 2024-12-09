//
//  RouteProgressEntity+CoreDataProperties.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-05.
//
//

import Foundation
import CoreData


extension RouteProgressEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RouteProgressEntity> {
        return NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
    }

    @NSManaged public var completedDistance: Double
    @NSManaged public var completedMilestones: Data?
    @NSManaged public var id: UUID?
    @NSManaged public var routeId: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var totalDistance: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isActive: Bool
    @NSManaged public var completionDate: Date?
    @NSManaged public var dailyProgressData: Data?
    @NSManaged public var dailyHealthData: NSSet?

}

// MARK: Generated accessors for dailyHealthData
extension RouteProgressEntity {

    @objc(addDailyHealthDataObject:)
    @NSManaged public func addToDailyHealthData(_ value: DailyHealthData)

    @objc(removeDailyHealthDataObject:)
    @NSManaged public func removeFromDailyHealthData(_ value: DailyHealthData)

    @objc(addDailyHealthData:)
    @NSManaged public func addToDailyHealthData(_ values: NSSet)

    @objc(removeDailyHealthData:)
    @NSManaged public func removeFromDailyHealthData(_ values: NSSet)

}

extension RouteProgressEntity : Identifiable {

}
