import Foundation
import CoreLocation
import MapKit
import CoreData
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentRoute: [CLLocationCoordinate2D] = []
    @Published var isTracking = false

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let context: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private var locationQueue: [CLLocation] = [] // Buffer for locations before processing
    private let queueThreshold = 5 // Process every 5 locations
    
    // Location tracking optimization properties
    private var lastLocation: CLLocation?
    private let minimumDistance: CLLocationDistance = 10
    private let minimumTimeInterval: TimeInterval = 3
    private var lastUpdateTime: Date?
    private let accuracyThreshold: CLLocationAccuracy = 20 // 20 meters accuracy
    private let maxSpeed: CLLocationSpeed = 30 // max 30 m/s (~67 mph)
    private let maxCourseChange: CLLocationDirection = 45 // max 45 degree change
    
    // MARK: - Initialization
    init(container: NSPersistentContainer) {
        self.context = container.viewContext
        self.backgroundContext = container.newBackgroundContext()
        self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        setUpLocationManager()
        setUpNotifications()
        
 
        }
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
 
        
        
        private func setUpLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.distanceFilter = 10
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.activityType = .fitness
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.showsBackgroundLocationIndicator = true
            
        }

    private func setUpNotifications() {
        NotificationCenter.default.addObserver(
                   self,
                   selector: #selector(managedObjectContextDidSave),
                   name: .NSManagedObjectContextDidSave,
                   object: backgroundContext
               )
    }
    
    private func startLocationUpdatesIfAuthorized() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("Starting location updates...")
        } else {
            print("Location authorization not granted")
        }
    }
    
    // MARK: - Location Tracking Methods
    private func shouldUpdateLocation(newLocation: CLLocation) -> Bool {
        guard isTracking else { return false }
            guard let lastLocation = lastLocation, let lastUpdateTime = lastUpdateTime else { return true }

           
           // Time check
           let timePassedOK = Date().timeIntervalSince(lastUpdateTime) >= minimumTimeInterval
           
           // Distance check
           let distanceOK = newLocation.distance(from: lastLocation) >= minimumDistance
           
           // Accuracy check
           let accuracyOK = newLocation.horizontalAccuracy <= accuracyThreshold
           
           // Speed check
           let speedOK = newLocation.speed <= maxSpeed && newLocation.speed >= 0
           
           // Course change check (filter out erratic movements)
           let courseDifferenceOK = abs(newLocation.course - lastLocation.course) <= maxCourseChange
           
           return timePassedOK && distanceOK && accuracyOK && speedOK && courseDifferenceOK
       }
    
    // MARK: - Public Methods
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        isTracking = true
        currentRoute.removeAll()
        locationQueue.removeAll()
        lastLocation = nil
        lastUpdateTime = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        let routeToSave = currentRoute
        saveRoute(coordinates: routeToSave)
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
                
        DispatchQueue.main.async {
            guard newLocation.horizontalAccuracy <= self.accuracyThreshold else { return }
                    
            let shouldUpdate = self.shouldUpdateLocation(newLocation: newLocation)
            if shouldUpdate {
                self.location = newLocation
                if self.isTracking {
                    self.locationQueue.append(newLocation)
                    if self.locationQueue.count >= self.queueThreshold {
                        self.processLocationQueue()
                    }
                }
                self.lastLocation = newLocation
                self.lastUpdateTime = Date()
            }
        }
    }
    
    private func processLocationQueue() {
        guard locationQueue.count >= 2 else { return }
        
        let locations = locationQueue
        locationQueue.removeAll()
        
        let request = MKDirections.Request()
        request.transportType = .walking
        
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locations.first!.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: locations.last!.coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self,
                  let route = response?.routes.first else {
                // Fallback to raw coordinates
                DispatchQueue.main.async {
                                self?.currentRoute.append(contentsOf: locations.map { $0.coordinate })
                            }
                return
            }
                        
            DispatchQueue.main.async {
                var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: route.polyline.pointCount)
                route.polyline.getCoordinates(&coords, range: NSRange(location: 0,
                                                        length: route.polyline.pointCount))
                            
                // Add the road-snapped coordinates
                self.currentRoute.append(contentsOf: coords)
            }
        }
    }

    
    nonisolated func locationManager (_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.startLocationUpdatesIfAuthorized()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        locationManager.startUpdatingLocation()
    }

    // MARK: - Core Data Methods
    @objc private func managedObjectContextDidSave(_ notification: Notification) {
        DispatchQueue.main.async {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    private func saveRoute(coordinates: [CLLocationCoordinate2D]) {
        if !locationQueue.isEmpty {
                   processLocationQueue()
               }
        
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
        
        for i in 0..<coordinates.count-1 {
            let loc1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let loc2 = CLLocation(latitude: coordinates[i+1].latitude, longitude: coordinates[i+1].longitude)
            distance += loc1.distance(from: loc2)
        }
        
        return distance
    }
    
    func fetchSavedRoutes() -> [Route] {
        let fetchRequest: NSFetchRequest<Route> = Route.fetchRequest()
        
        do {
            let routes = try context.fetch(fetchRequest)
            print("Fetched \(routes.count) saved routes")
            return routes
        } catch {
            print("Error fetching routes: \(error)")
            return []
        }
    }
}
