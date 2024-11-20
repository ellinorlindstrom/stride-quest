import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // Debug print to verify model URL
        guard let modelURL = Bundle.main.url(forResource: "StrideQuest", withExtension: "momd") else {
            fatalError("Failed to find CoreData model file")
        }
        print("CoreData model URL: \(modelURL)")
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load CoreData model")
        }
        
        container = NSPersistentContainer(name: "StrideQuest", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Add more verbose error logging
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("Core Data store failed to load with error: \(error)")
                print("Error description: \(error.localizedDescription)")
                print("Error user info: \(error.userInfo)")
                
                // Check common issues
                if let detailedError = error.userInfo["NSDetailedErrors"] as? [NSError] {
                    print("Detailed errors: \(detailedError)")
                }
                
                fatalError("Failed to load Core Data stack: \(error)")
            } else {
                print("Successfully loaded persistent store: \(description)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
