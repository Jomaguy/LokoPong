import SwiftUI
import FirebaseFirestore

/**
 * AdminNotificationsView
 *
 * Purpose: Admin interface for sending push notifications
 * - Allows sending messages to all devices
 * - Supports broadcasting to topic subscribers
 * - Provides intuitive UI for notification composition
 */
struct AdminNotificationsView: View {
    @StateObject private var viewModel = AdminNotificationsViewModel()
    
    @State private var notificationTitle = ""
    @State private var notificationMessage = ""
    @State private var selectedType = "All Devices"
    
    private let notificationTypes = ["All Devices", "Tournament Topic"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Send Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Send push notifications to users of the LokoPong app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Notification type selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notification Type")
                        .font(.headline)
                    
                    Picker("Notification Type", selection: $selectedType) {
                        ForEach(notificationTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(selectedType == "All Devices" ? 
                        "Send to all devices with the app installed" : 
                        "Send to devices subscribed to tournament updates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                // Notification content
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notification Title")
                        .font(.headline)
                    
                    TextField("Enter notification title", text: $notificationTitle)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    Text("Notification Message")
                        .font(.headline)
                    
                    TextEditor(text: $notificationMessage)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Preview Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(notificationTitle.isEmpty ? "Notification Title" : notificationTitle)
                            .font(.headline)
                        
                        Text(notificationMessage.isEmpty ? "Notification message will appear here" : notificationMessage)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.bottom)
                
                // Status Message
                if viewModel.showStatus {
                    HStack {
                        Image(systemName: viewModel.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(viewModel.isSuccess ? .green : .red)
                        
                        Text(viewModel.statusMessage)
                            .font(.callout)
                            .foregroundColor(viewModel.isSuccess ? .green : .red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(viewModel.isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Send Button
                Button(action: {
                    if selectedType == "All Devices" {
                        viewModel.sendNotificationToAllDevices(title: notificationTitle, body: notificationMessage)
                    } else {
                        viewModel.sendNotificationToTopic(title: notificationTitle, body: notificationMessage)
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .padding(.trailing, 8)
                        }
                        
                        Text("Send Notification")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        notificationTitle.isEmpty || notificationMessage.isEmpty || viewModel.isLoading ?
                            Color.blue.opacity(0.5) : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(notificationTitle.isEmpty || notificationMessage.isEmpty || viewModel.isLoading)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Notifications")
    }
} 