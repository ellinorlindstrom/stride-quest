//
//  RoutePoint.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//
import Foundation
import CoreData

@objc(RoutePoint)
public class RoutePoint: NSManagedObject {
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var route: Route?
}

extension RoutePoint {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoutePoint> {
        return NSFetchRequest<RoutePoint>(entityName: "RoutePoint")
    }
}
