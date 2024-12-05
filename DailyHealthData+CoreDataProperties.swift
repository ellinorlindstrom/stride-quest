//
//  DailyHealthData+CoreDataProperties.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-05.
//
//

import Foundation
import CoreData


extension DailyHealthData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyHealthData> {
        return NSFetchRequest<DailyHealthData>(entityName: "DailyHealthData")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var distance: Double
    @NSManaged public var type: String?
    @NSManaged public var routeProgress: RouteProgressEntity?

}

extension DailyHealthData : Identifiable {

}
