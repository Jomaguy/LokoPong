import SwiftUI

struct AdminView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                Text("Coming soon: Team approval, tournament management, and notifications")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Placeholder for future admin features
                List {
                    Section(header: Text("Team Management")) {
                        HStack {
                            Image(systemName: "person.2.badge.gearshape")
                                .foregroundColor(.blue)
                            Text("Team Approvals")
                        }
                    }
                    
                    Section(header: Text("Tournament Control")) {
                        HStack {
                            Image(systemName: "trophy")
                                .foregroundColor(.orange)
                            Text("Update Match Results")
                        }
                    }
                    
                    Section(header: Text("Communication")) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.red)
                            Text("Send Notifications")
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Admin")
        }
    }
} 