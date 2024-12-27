import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background task
        HealthKitManager.shared.registerBackgroundTasks()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification response when user taps the notification
    func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            let userInfo = response.notification.request.content.userInfo
            
            if let type = userInfo["type"] as? String {
                switch type {
                case "milestone":
                    if let milestoneId = userInfo["milestoneId"] as? String {
                        DispatchQueue.main.async {
                            self.authManager.activeNotification = AuthenticationManager.ActiveNotification(
                                type: "milestone",
                                id: milestoneId
                            )
                        }
                    }
                default:
                    break
                }
            }
            
            completionHandler()
        }
    }
