import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var totalDistance: Double = 0 {
        didSet {
            let distanceInKilometers = totalDistance / 1000
            RouteManager.shared.updateProgress(withDistance: distanceInKilometers)
        }
    }
    @Published var isAuthorized = false
    
    private var observerQueries: [HKObserverQuery] = []
    
    // Types we want to read from HealthKit
    let typesToRead: Set = [
        HKQuantityType(.distanceWalkingRunning),
    ]
    
    // Request authorization and start observing
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthkitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        DispatchQueue.main.async {
            self.isAuthorized = true
            self.startObservingDistance()
            // Fetch initial distance when authorization is granted
            self.fetchTotalDistance()
        }
        try await setupBackgroundDelivery()
    }
    
    private func setupBackgroundDelivery() async throws {
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
        ]
        
        for distanceType in distanceTypes {
            try await healthStore.enableBackgroundDelivery(for: distanceType, frequency: .immediate)
        }
    }
    
    private func startObservingDistance() {
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
        ]
        
        for distanceType in distanceTypes {
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
            
            // Enable immediate background updates
            let anchorQuery = HKAnchoredObjectQuery(type: distanceType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
                if error == nil && samples?.count ?? 0 > 0 {
                    DispatchQueue.main.async {
                        self?.fetchTotalDistance()
                    }
                }
            }
            
            healthStore.execute(anchorQuery)
        }
    }
    
    func fetchTotalDistance() {
        let distanceTypes = [
            HKQuantityType(.distanceWalkingRunning),
        ]
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now
        )
        
        let group = DispatchGroup()
        var temporaryTotal: Double = 0
        
        for distanceType in distanceTypes {
            group.enter()
            
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                defer { group.leave() }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    return
                }
                
                let distance = sum.doubleValue(for: HKUnit.meter())
                temporaryTotal += distance
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
                self?.totalDistance = temporaryTotal
        }
    }
    
    deinit {
        for query in observerQueries {
            healthStore.stop(query)
        }
    }
}

enum HealthkitError: Error {
    case notAvailable
}
