import Foundation
import CoreLocation
import MapKit
import CoreData
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentRoute: [CLLocationCoordinate2D] = []
    @Published var isTracking = false
    
    private let context: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    
    
    init(container: NSPersistentContainer) {
        self.context = container.viewContext
        self.backgroundContext = container.newBackgroundContext()
        self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = .fitness
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("Starting location updates...")
        } else {
            print("Location authorization not granted")
        }
        
        NotificationCenter.default.addObserver(
                   self,
                   selector: #selector(managedObjectContextDidSave),
                   name: .NSManagedObjectContextDidSave,
                   object: backgroundContext
               )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func managedObjectContextDidSave(_ notification: Notification) {
        DispatchQueue.main.async {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        isTracking = true
        currentRoute.removeAll()
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        let routeToSave = currentRoute
        saveRoute(coordinates: routeToSave)
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location
            if self.isTracking {
                self.currentRoute.append(location.coordinate)
            }
        }
    }
    
    nonisolated func locationManager (_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    private func saveRoute(coordinates: [CLLocationCoordinate2D]) {
        guard !currentRoute.isEmpty else {return}
        
        backgroundContext.perform {
            let route = Route(context: self.backgroundContext)
            route.date = Date()
            route.distance = self.calculateDistance(for: coordinates)
            
            for coordinate in coordinates {
                let point = RoutePoint(context: self.backgroundContext)
                point.latitude = coordinate.latitude
                point.longitude = coordinate.longitude
                point.route = route
            }
            
            do {
                try self.backgroundContext.save()
                
                DispatchQueue.main.async {
                    self.context.perform {
                        try? self.context.save()
                    }
                }
            } catch {
                print("Error saving route: \(error)")
            }
        }
    }
    
    private func calculateDistance(for coordinates: [CLLocationCoordinate2D]) -> Double {
        var distance = 0.0
        guard coordinates.count > 1 else { return distance }
        
        for i in 0..<currentRoute.count-1 {
            let loc1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let loc2 = CLLocation(latitude: coordinates[i+1].latitude, longitude: coordinates[i+1].longitude)
            distance += loc1.distance(from: loc2)
        }
        
        return distance
    }
    
    func fetchSavedRoutes() -> [Route] {
        let fetchRequest: NSFetchRequest<Route> = Route.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching routes: \(error)")
            return []
        }
    }
}
