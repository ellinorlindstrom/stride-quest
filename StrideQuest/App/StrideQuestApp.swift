import SwiftUI

@main
struct StrideQuestApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject var healthManager = HealthKitManager()

    
    init() {
        _authManager = StateObject(wrappedValue: AuthenticationManager())
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
                .environmentObject(healthManager)
        }
    }
}
