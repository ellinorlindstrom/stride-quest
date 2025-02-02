import SwiftUI
import BackgroundTasks

@main
struct StrideQuestApp: App {
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var healthManager = HealthKitManager.shared
    private let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
                .environmentObject(healthManager)
                .environmentObject(routeManager)
                .task {
                    // First ensure HealthKit is authorized
                    await requestHealthKitAuthorization()
                    // Then restore state
                    await routeManager.restoreState()
                }
                .onAppear {
                    print("App started with Core Data context: \(persistenceController.container.viewContext)")
                }
        }
    }
    
    private func requestHealthKitAuthorization() async {
        do {
            try await healthManager.requestAuthorization()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
}
