import Foundation
import HealthKit
import SwiftUI
import BackgroundTasks

class HealthKitManager: ObservableObject {
    // MARK: - Singleton
    private static var instance: HealthKitManager?
    static var shared: HealthKitManager {
        if instance == nil {
            instance = HealthKitManager()
        }
        return instance!
    }
    
    // MARK: - Properties
    @AppStorage("lastKnownDistance") private var lastKnownDistance: Double = 0
    @AppStorage("isHealthKitAuthorized") private var isHealthKitAuthorized = false
    @AppStorage("routeTrackingStartDistance") private var savedRouteStartDistance: Double = 0
    
    let healthStore = HKHealthStore()
    
    // Published properties
    @Published var routeStartDistance: Double = 0
    @Published var isAuthorized = false
    @Published var totalDistance: Double = 0
    @Published var isTrackingRoute: Bool = false
    
    // For route tracking
    private var routeTrackingStartDistance: Double = 0
    
    //Computed property
    // Add this property
    var routeRelativeDistance: Double {
        guard isTrackingRoute else { return 0 }
        return max(0, totalDistance - routeTrackingStartDistance)
    }
    
    private init() {
        self.totalDistance = lastKnownDistance
        self.routeTrackingStartDistance = savedRouteStartDistance
        print("This is init in HealthKitManager, totaldistance:", self.totalDistance)
        print("This is init in HealthKitManager, routetrackingstartdistance:", self.totalDistance)

        }
    
    
    private let backgroundTaskIdentifier = "com.ellinorlindstrom.StrideQuest.StrideQuest.healthkit.refresh"
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGProcessingTask)
        }
    }
    
    private func scheduleNextBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        scheduleNextBackgroundTask()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        fetchTotalDistance()
        task.setTaskCompleted(success: true)
    }
    
    func setupBackgroundDelivery() async throws {
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.distanceWheelchair),
        ]
        
        for distanceType in distanceTypes {
            try await healthStore.enableBackgroundDelivery(for: distanceType, frequency: .immediate)
        }
        
        // Register for background updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundUpdate),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func handleBackgroundUpdate() {
        guard RouteManager.shared.currentRoute != nil else { return }
        
        let backgroundTask = UIApplication.shared.beginBackgroundTask {
            // Handle expiration
        }
        
        fetchTotalDistance()
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
    }
    
    
    private var observerQueries: [HKObserverQuery] = []
    
    // Types we want to read from HealthKit
    let typesToRead: Set = [
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
        HKQuantityType(.distanceWheelchair),
    ]
    
    func markRouteStart() {
        routeTrackingStartDistance = totalDistance
        routeStartDistance = totalDistance
        savedRouteStartDistance = totalDistance
        isTrackingRoute = true  // Ensure this is set
        print("🎯 Route started at distance: \(routeStartDistance)")
        print("  - isTrackingRoute set to: \(isTrackingRoute)")
        
        // Force an immediate distance fetch
        fetchTotalDistance()
    }
    
    func stopTracking() {
        isTrackingRoute = false
        print("🛑 Route tracking stopped")
    }
    
    // Request authorization and start observing
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthkitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        DispatchQueue.main.async {
            self.isAuthorized = true
            self.startObservingDistance()
            self.fetchTotalDistance()
            print("🍏 requestAuthorization func DispatchQueue.main.async",
            "- self.isAuthorized", self.isAuthorized,
            "- self.startObservingDistance", self.startObservingDistance,
                  "self.fetchTotalDistance:",self.fetchTotalDistance)
        }
        try await setupBackgroundDelivery()
    }
    
    func handleDistanceUpdate(_ newDistance: Double) {
        totalDistance = newDistance
        
        if isTrackingRoute && RouteManager.shared.currentRoute != nil {
            let relativeDistance = routeRelativeDistance
            print("📏 Distance Update:")
            print("  - Total Distance: \(totalDistance)")
            print("  - Start Distance: \(routeTrackingStartDistance)")
            print("  - Relative Distance: \(relativeDistance)")
            
            RouteManager.shared.updateProgress(withDistance: relativeDistance, source: "healthkit")
        }
        
        // Save both distances
        lastKnownDistance = totalDistance
        savedRouteStartDistance = routeTrackingStartDistance  // This ensures the start distance persists
        
        HealthDataStore.shared.saveHealthData(
            totalDistance,
            date: Date(),
            type: HKQuantityType(.distanceWalkingRunning)
        )
    }
    
    func fetchTotalDistance() {
        let calendar = Calendar.current
        let now = Date()
        let startDate = RouteManager.shared.currentProgress?.startDate ?? calendar.startOfDay(for: now)
        
        
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.distanceWheelchair)
        ]
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now
        )
        
        var temporaryTotal: Double = 0
        let group = DispatchGroup()
        
        for distanceType in distanceTypes {
            group.enter()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { query, results, error in
                defer { group.leave() }
                
                guard let results = results else { return }
                
                results.enumerateStatistics(from: startDate, to: now) { statistics, stop in
                    if let sum = statistics.sumQuantity() {
                        let distance = sum.doubleValue(for: HKUnit.meter())
                        temporaryTotal += distance
                    }
                }
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            let newDistance = temporaryTotal / 1000.0
            self?.handleDistanceUpdate(newDistance)
            
            HealthDataStore.shared.saveHealthData(
                temporaryTotal / 1000.0,
                date: Date(),
                type: HKQuantityType(.distanceWalkingRunning)
            )
        }
    }
    private func startObservingDistance() {
        // Immediate update when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Set up observer queries for each distance type
        for distanceType in typesToRead {
            let query = HKObserverQuery(sampleType: distanceType, predicate: nil) { [weak self] _, completion, error in
                if error == nil {
                    DispatchQueue.main.async {
                        self?.fetchTotalDistance()
                    }
                }
                completion()
            }
            
            observerQueries.append(query)
            healthStore.execute(query)
        }
    }
    
    @objc private func appBecameActive() {
        fetchTotalDistance()
    }
}

enum HealthkitError: Error {
    case notAvailable
    case timeout
}
