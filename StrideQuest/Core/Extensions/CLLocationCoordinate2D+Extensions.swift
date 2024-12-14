//
//  CLLocationCoordinate2D+Extensions.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-14.
//
import CoreLocation

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let toLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0  // In kilometers
    }
}
