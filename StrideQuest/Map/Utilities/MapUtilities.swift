//
//  MapUtilities.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-10.
//

import SwiftUI
import MapKit

func getMilestoneCoordinate(milestone: RouteMilestone, coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
    let milestoneDistance = milestone.distanceFromStart
    var currentDistance: Double = 0
    
    for i in 1..<coordinates.count {
        let previous = coordinates[i - 1]
        let current = coordinates[i]
        let segmentDistance = calculateDistance(from: previous, to: current)
        
        if currentDistance + segmentDistance >= milestoneDistance {
            let remainingDistance = milestoneDistance - currentDistance
            let fraction = remainingDistance / segmentDistance
            let lat = previous.latitude + (current.latitude - previous.latitude) * fraction
            let lon = previous.longitude + (current.longitude - previous.longitude) * fraction
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        currentDistance += segmentDistance
    }
    
    return coordinates.first ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
}


func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
}
