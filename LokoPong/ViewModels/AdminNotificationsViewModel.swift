import Foundation
import FirebaseCore
import FirebaseFirestore

/**
 * AdminNotificationsViewModel
 * 
 * Purpose: Handles sending push notifications from the admin panel
 * - Creates notification documents in Firestore
 * - Cloud Functions handle the actual delivery to devices
 * - Provides status feedback for notification delivery
 */
class AdminNotificationsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var statusMessage = ""
    @Published var showStatus = false
    @Published var isSuccess = false
    
    private let db = Firestore.firestore()
    
    // Send notification to all registered devices
    func sendNotificationToAllDevices(title: String, body: String) {
        self.isLoading = true
        self.showStatus = false
        
        // Create notification document for Cloud Function to process
        let notificationData: [String: Any] = [
            "title": title,
            "body": body,
            // No token or topic means send to all devices
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        // Add to Firestore - Cloud Function will handle sending to all devices
        db.collection("notifications").addDocument(data: notificationData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.showError("Error creating notification: \(error.localizedDescription)")
                    return
                }
                
                self.showSuccess("Notification sent to all devices successfully!")
            }
        }
    }
    
    // Send to tournament topic (all users who subscribed to tournament updates)
    func sendNotificationToTopic(title: String, body: String) {
        self.isLoading = true
        self.showStatus = false
        
        // Create notification document for Cloud Function to process
        let notificationData: [String: Any] = [
            "title": title,
            "body": body,
            "topic": "tournaments",
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        // Add to Firestore - Cloud Function will handle sending to the topic
        db.collection("notifications").addDocument(data: notificationData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.showError("Error creating topic notification: \(error.localizedDescription)")
                    return
                }
                
                self.showSuccess("Notification sent to tournament subscribers successfully!")
            }
        }
    }
    
    // Helper to show success message
    private func showSuccess(_ message: String) {
        self.statusMessage = message
        self.showStatus = true
        self.isSuccess = true
        self.isLoading = false
    }
    
    // Helper to show error message
    private func showError(_ message: String) {
        self.statusMessage = message
        self.showStatus = true
        self.isSuccess = false
        self.isLoading = false
    }
} 