import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "StrideQuest")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}


//import CoreData
//
//class PersistenceController {
//    static let shared = PersistenceController()
//    
//    let container: NSPersistentContainer
//    
//    init(inMemory: Bool = false) {
//        container = NSPersistentContainer(name: "StrideQuest")
//        
//        if inMemory {
//            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
//        }
//        
//        // Add migration options
//        let description = container.persistentStoreDescriptions.first
//        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
//        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
//        
//        // Try loading the store
//        container.loadPersistentStores { [weak self] description, error in
//            if let error = error as NSError? {
//                // If there's an error, try to recover by deleting the store
//                print("Core Data store failed to load with error: \(error)")
//                print("Error description: \(error.localizedDescription)")
//                
//                // Attempt to recover by deleting and recreating the store
//                if let storeURL = description.url {
//                    do {
//                        try FileManager.default.removeItem(at: storeURL)
//                        print("Deleted corrupted store at: \(storeURL)")
//                        
//                        // Try loading again
//                        try self?.container.persistentStoreCoordinator.addPersistentStore(
//                            ofType: NSSQLiteStoreType,
//                            configurationName: nil,
//                            at: storeURL,
//                            options: [
//                                NSMigratePersistentStoresAutomaticallyOption: true,
//                                NSInferMappingModelAutomaticallyOption: true
//                            ]
//                        )
//                        print("Successfully recreated store")
//                    } catch {
//                        print("Recovery failed: \(error)")
//                        fatalError("Failed to recover from Core Data error: \(error)")
//                    }
//                } else {
//                    fatalError("Failed to load Core Data stack and couldn't recover: \(error)")
//                }
//            }
//        }
//        
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//    }
//    
//    func resetStore() {
//        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
//        
//        do {
//            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
//            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
//            print("Store reset successfully")
//        } catch {
//            print("Failed to reset store: \(error)")
//        }
//    }
//}
