import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Set up notifications
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("✅ Notification permission granted")
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    print("❌ Error requesting notification permission: \(error.localizedDescription)")
                }
            }
        )
        
        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banners even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle user interaction with the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap here
        let userInfo = response.notification.request.content.userInfo
        print("User interacted with notification: \(userInfo)")
        
        completionHandler()
    }
    
    // Firebase Messaging token handling
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Store the token for later use
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            UserDefaults.standard.set(token, forKey: "fcmToken")
            
            // Save the token to Firestore
            saveTokenToFirestore(token: token)
            
            // Subscribe to tournament topic for broadcasts
            Messaging.messaging().subscribe(toTopic: "tournaments") { error in
                if let error = error {
                    print("Error subscribing to topic: \(error)")
                } else {
                    print("Subscribed to 'tournaments' topic")
                }
            }
        }
    }
    
    // Save device token to Firestore
    private func saveTokenToFirestore(token: String) {
        let db = Firestore.firestore()
        
        // Use device ID as document ID for token document
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        db.collection("deviceTokens").document(deviceId).setData([
            "token": token,
            "device": UIDevice.current.model,
            "os": UIDevice.current.systemName + " " + UIDevice.current.systemVersion,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("❌ Error saving device token: \(error.localizedDescription)")
            } else {
                print("✅ Device token saved to Firestore")
            }
        }
    }
    
    // Handle receiving remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification: \(userInfo)")
        
        // Process notification data if needed
        
        completionHandler(.newData)
    }
} 