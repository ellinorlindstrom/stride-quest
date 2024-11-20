//
//  Route.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//
import Foundation
import CoreData

@objc(Route)
public class Route: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var distance: Double
    @NSManaged public var points: Set<RoutePoint>?
    
    var pointsArray: [RoutePoint] {
        let set = points ?? []
        return Array(set).sorted { $0.latitude < $1.latitude }
    }
}

extension Route {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Route> {
        return NSFetchRequest<Route>(entityName: "Route")
    }
}
