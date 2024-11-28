import SwiftUI

@main
struct StrideQuestApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var healthManager = HealthKitManager.shared

    
    init() {
        _authManager = StateObject(wrappedValue: AuthenticationManager())
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
                .environmentObject(healthManager)
                .task {
                                    do {
                                        try await healthManager.requestAuthorization()
                                    } catch {
                                        print("Error setting up HealthKit: \(error)")
                                    }
                                }
                        }
                    }
                }
