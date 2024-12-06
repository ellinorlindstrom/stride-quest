import CoreData
import HealthKit

class HealthDataStore {
    static let shared = HealthDataStore()
    let persistentContainer: NSPersistentContainer
    
    init() {
        persistentContainer = PersistenceController.shared.container
    }
    
    func fetchAllRouteProgress() -> [RouteProgress] {
            let context = persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { entity in
                    RouteProgress(
                        id: entity.id ?? UUID(),
                        routeId: entity.routeId ?? UUID(),
                        startDate: entity.startDate ?? Date(),
                        completedDistance: entity.completedDistance,
                        lastUpdated: entity.lastUpdated ?? Date(),
                        completedMilestones: entity.getCompletedMilestones(),
                        totalDistance: entity.totalDistance,
                        dailyProgress: entity.getDailyProgress(),
                        isCompleted: entity.isCompleted,
                        completionDate: entity.completionDate
                    )
                }
            } catch {
                print("Failed to fetch all route progress: \(error)")
                return []
            }
        }
    
    func saveHealthData(_ distance: Double, date: Date, type: HKQuantityType) {
            let context = persistentContainer.viewContext
            let healthData = DailyHealthData(context: context)
            
            healthData.id = UUID()
            healthData.date = date
            healthData.distance = distance
            healthData.type = type.identifier
            
        if let currentProgress = RouteManager.shared.currentProgress {
                let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %@", currentProgress.id as CVarArg)
                
                do {
                    if let routeProgressEntity = try context.fetch(fetchRequest).first {
                        healthData.routeProgress = routeProgressEntity
                    }
                } catch {
                    print("Failed to link health data to route progress: \(error)")
                }
            }
            
            do {
                try context.save()
                print("Health data saved successfully")
            } catch {
                print("Failed to save health data: \(error)")
                context.rollback()
            }
        }

    
    func updateRouteProgress(_ progress: RouteProgress) {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", progress.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let entity: RouteProgressEntity
            
            if let existingEntity = results.first {
                entity = existingEntity
            } else {
                entity = RouteProgressEntity(context: context)
                entity.id = progress.id
            }
            
            // Update the entity
            entity.routeId = progress.routeId
            entity.startDate = progress.startDate
            entity.completedDistance = progress.completedDistance
            entity.lastUpdated = progress.lastUpdated
            entity.totalDistance = progress.totalDistance
            entity.isCompleted = progress.isCompleted
            entity.completionDate = progress.completionDate
            entity.setCompletedMilestones(progress.completedMilestones)
            entity.setDailyProgress(progress.dailyProgress)
            
            try context.save()
        } catch {
            print("Failed to save route progress: \(error)")
        }
    }
    
    func fetchAccumulatedDistance(for routeProgress: RouteProgress) -> Double {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<DailyHealthData>(entityName: "DailyHealthData")
        
        // Create predicate to fetch all health data linked to this route progress
        let routeProgressPredicate = NSPredicate(format: "routeProgress.id == %@", routeProgress.id as CVarArg)
        fetchRequest.predicate = routeProgressPredicate
        
        do {
            let healthDataEntries = try context.fetch(fetchRequest)
            let totalDistance = healthDataEntries.reduce(0) { $0 + $1.distance }
            return totalDistance
        } catch {
            print("Failed to fetch accumulated distance: \(error)")
            return 0
        }
    }
    
    func fetchRouteProgress(id: UUID) -> RouteProgress? {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<RouteProgressEntity>(entityName: "RouteProgressEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            guard let entity = try context.fetch(fetchRequest).first else { return nil }
            
            return RouteProgress(
                id: entity.id ?? UUID(),
                routeId: entity.routeId ?? UUID(),
                startDate: entity.startDate ?? Date(),
                completedDistance: entity.completedDistance,
                lastUpdated: entity.lastUpdated ?? Date(),
                completedMilestones: entity.getCompletedMilestones(),
                totalDistance: entity.totalDistance,
                dailyProgress: entity.getDailyProgress(),
                isCompleted: entity.isCompleted,
                completionDate: entity.completionDate
            )
        } catch {
            print("Failed to fetch route progress: \(error)")
            return nil
        }
    }
}