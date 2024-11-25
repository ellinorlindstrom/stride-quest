import SwiftUI

@main
struct StrideQuestApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject private var authManager = AuthenticationManager()

    
    init() {
        let container = persistenceController.container

        _authManager = StateObject(wrappedValue: AuthenticationManager())
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
        }
    }
}


//@main
//struct StrideQuestApp: App {
//    @StateObject private var locationManager = LocationManager(container: PersistenceController.shared.container)
//    @StateObject private var authManager = AuthenticationManager()
//    
//    let persistenceController = PersistenceController.shared
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                .environmentObject(locationManager)
//                .environmentObject(authManager)
//        }
//    }
//}
