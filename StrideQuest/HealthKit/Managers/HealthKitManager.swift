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
        guard RouteManager.shared.currentRoute != nil else {
               print("No active route, skipping background update")
               return
           }
           
        
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
        if RouteManager.shared.currentProgress != nil {
            // Resuming existing route
            routeTrackingStartDistance = savedRouteStartDistance
            isTrackingRoute = true
        } else {
            // Starting new route
            totalDistance = 0
            routeTrackingStartDistance = 0
            routeStartDistance = 0
            savedRouteStartDistance = 0
            isTrackingRoute = true
        }
        
        fetchTotalDistance()
    }
    
    
    func resumeRoute(startDistance: Double) {
        routeTrackingStartDistance = startDistance
        savedRouteStartDistance = startDistance
        routeStartDistance = startDistance
        isTrackingRoute = true
        print("▶️ Resuming route tracking from distance: \(startDistance)")
        fetchTotalDistance()
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthkitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        DispatchQueue.main.async {
            self.isAuthorized = true
            self.startObservingDistance()
            self.fetchTotalDistance()
        }
        try await setupBackgroundDelivery()
    }
    
    func handleDistanceUpdate(_ newDistance: Double) {
        totalDistance = newDistance
        
        if isTrackingRoute && RouteManager.shared.currentRoute != nil {
            let relativeDistance = routeRelativeDistance
            RouteManager.shared.updateProgress(withDistance: relativeDistance, source: "healthkit")
        }
        
        // Save both distances
        lastKnownDistance = totalDistance
        savedRouteStartDistance = routeTrackingStartDistance
        
        HealthDataStore.shared.saveHealthData(
            totalDistance,
            date: Date(),
            type: HKQuantityType(.distanceWalkingRunning)
        )
    }
    
    func fetchTotalDistance() {
        guard let routeStartDate = RouteManager.shared.currentProgress?.startDate else {
               return
           }

        let now = Date()
        
        
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.distanceWheelchair)
        ]
        
        let predicate = HKQuery.predicateForSamples(
            withStart: routeStartDate,
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
                anchorDate: routeStartDate,
                intervalComponents: DateComponents(minute: 1)
            )
            
            query.initialResultsHandler = { query, results, error in
                defer { group.leave() }
                
                guard let results = results else { return }
                
                results.enumerateStatistics(from: routeStartDate, to: now) { statistics, stop in
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
        guard RouteManager.shared.currentRoute != nil else {
            print("No active route, skipping active update")
            return
        }
        fetchTotalDistance()
    }
}

enum HealthkitError: Error {
    case notAvailable
    case timeout
}
