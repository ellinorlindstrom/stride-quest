// HealthKitManager.swift
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        
        let types = Set([
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        ])
        
        try await healthStore.requestAuthorization(toShare: [], read: types)
    }
    
    // Query steps
    func queryStepCount(for date: Date) async throws -> Double {
        let sum = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.startOfDay(for: date),
                end: Calendar.current.startOfDay(for: Date()),
                options: .strictStartDate
            )
            
            let query = HKStatisticsQuery(
                quantityType: stepsQuantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            
            healthStore.execute(query)
        }
        
        return sum
    }
    
    // Query distance
    func queryDistance(for date: Date) async throws -> Double {
        let distance = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.startOfDay(for: date),
                end: Calendar.current.startOfDay(for: Date()),
                options: .strictStartDate
            )
            
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                continuation.resume(returning: distance)
            }
            
            healthStore.execute(query)
        }
        
        return distance
    }
}
