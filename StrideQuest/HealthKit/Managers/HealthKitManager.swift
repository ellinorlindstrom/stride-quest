import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    @AppStorage("lastKnownDistance") private var lastKnownDistance: Double = 0
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    /// Starting distance in kilometers when a route begins
    @Published var routeStartDistance: Double = 0
    @Published var isAuthorized = false
    @Published var totalDistance: Double = 0 {
        didSet {
            if !RouteManager.shared.activeRouteIds.isEmpty {
                let relativeDistance = max(0, totalDistance - routeStartDistance)
                RouteManager.shared.updateProgress(withDistance: relativeDistance, source: "healthkit")
            }
            
            HealthDataStore.shared.saveHealthData(
                totalDistance,
                date: Date(),
                type: HKQuantityType(.distanceWalkingRunning)
            )
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
    
    init() {
        self.totalDistance = lastKnownDistance
    }
    
    func markRouteStart() {
        routeStartDistance = totalDistance
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
        }
        try await setupBackgroundDelivery()
    }
    
    private func setupBackgroundDelivery() async throws {
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.distanceWheelchair),
        ]
        
        for distanceType in distanceTypes {
            try await healthStore.enableBackgroundDelivery(for: distanceType, frequency: .immediate)
        }
    }
    
//    private func startObservingDistance() {
//        let distanceTypes = [
//            HKQuantityType(.distanceWalkingRunning),
//            HKQuantityType(.distanceCycling),
//            HKQuantityType(.distanceSwimming),
//            HKQuantityType(.distanceWheelchair),
//        ]
//        
//        for distanceType in distanceTypes {
//            let query = HKObserverQuery(sampleType: distanceType, predicate: nil) { [weak self] _, completion, error in
//                if error == nil {
//                    DispatchQueue.main.async {
//                        self?.fetchTotalDistance()
//                    }
//                }
//                completion()
//            }
//            
//            observerQueries.append(query)
//            healthStore.execute(query)
//            
//        }
//    }
    
    func fetchTotalDistance() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.distanceWheelchair)
        ]
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
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
                anchorDate: startOfDay,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { query, results, error in
                defer { group.leave() }
                
                guard let results = results else { return }
                
                results.enumerateStatistics(from: startOfDay, to: now) { statistics, stop in
                    if let sum = statistics.sumQuantity() {
                        let distance = sum.doubleValue(for: HKUnit.meter())
                        temporaryTotal += distance
                    }
                }
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.totalDistance = temporaryTotal / 1000.0
            
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
