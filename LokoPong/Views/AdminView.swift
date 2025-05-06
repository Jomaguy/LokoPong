import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Auth View Model for Admin Login
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isAuthenticated = false
                    print("❌ Login error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = authResult?.user else {
                    self?.errorMessage = "Authentication failed"
                    self?.isAuthenticated = false
                    return
                }
                
                // You can check for admin status here if needed
                // For example, by checking a claim or a specific email domain
                self?.isAuthenticated = true
                print("✅ Successfully logged in: \(user.email ?? "unknown")")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            print("✅ Successfully logged out")
        } catch let error {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

// TeamWithApproval - Extended model for admin view with approval status
struct TeamWithApproval: Identifiable {
    let id: String
    let name: String
    let players: [String]
    var isApproved: Bool
    
    // Create from TeamData
    init(from team: TeamData, isApproved: Bool = false) {
        self.id = team.id
        self.name = team.name
        self.players = team.players
        self.isApproved = isApproved
    }
    
    // Direct initializer
    init(id: String, name: String, players: [String] = [], isApproved: Bool = false) {
        self.id = id
        self.name = name
        self.players = players
        self.isApproved = isApproved
    }
}

// TeamApprovalsViewModel - For managing team approvals in admin section
@MainActor
class TeamApprovalsViewModel: ObservableObject {
    @Published var teams: [TeamWithApproval] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func loadTeams() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection("teams").getDocuments()
            teams = snapshot.documents.compactMap { document -> TeamWithApproval? in
                let data = document.data()
                guard let name = data["name"] as? String else {
                    return nil
                }
                
                // Extract player information
                let player1Name = data["player1Name"] as? String
                let player2Name = data["player2Name"] as? String
                
                // Create array of player names (filtering out nil values)
                var players: [String] = []
                if let player1 = player1Name, !player1.isEmpty {
                    players.append(player1)
                }
                if let player2 = player2Name, !player2.isEmpty {
                    players.append(player2)
                }
                
                let isApproved = data["isApproved"] as? Bool ?? false
                
                return TeamWithApproval(id: document.documentID, name: name, players: players, isApproved: isApproved)
            }
            isLoading = false
        } catch {
            self.error = "Failed to load teams: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func toggleApproval(for teamId: String, currentStatus: Bool) async {
        do {
            try await db.collection("teams").document(teamId).updateData([
                "isApproved": !currentStatus
            ])
            
            // Update local data
            if let index = teams.firstIndex(where: { $0.id == teamId }) {
                teams[index].isApproved.toggle()
            }
        } catch {
            self.error = "Failed to update team: \(error.localizedDescription)"
        }
    }
}

// TeamApprovalsView - Admin interface for approving teams
struct TeamApprovalsView: View {
    @StateObject private var viewModel = TeamApprovalsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading teams...")
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
            } else if viewModel.teams.isEmpty {
                Text("No teams to approve")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.teams) { team in
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                // Team name
                                Text(team.name)
                                    .font(.headline)
                                
                                // Player names
                                if !team.players.isEmpty {
                                    Text(team.players.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            // Approval status and toggle button
                            Button(action: {
                                Task {
                                    await viewModel.toggleApproval(for: team.id, currentStatus: team.isApproved)
                                }
                            }) {
                                Image(systemName: team.isApproved ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(team.isApproved ? .green : .gray)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Team Approvals")
        .onAppear {
            Task {
                await viewModel.loadTeams()
            }
        }
        .refreshable {
            await viewModel.loadTeams()
        }
    }
}

// AdminView - Main container view for admin functionality
struct AdminView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if authViewModel.isAuthenticated {
                    // Admin Dashboard content
                    AdminDashboardView(authViewModel: authViewModel)
                } else {
                    // Login screen
                    AdminLoginView(authViewModel: authViewModel)
                }
            }
            .navigationTitle("Admin")
            .toolbar {
                if authViewModel.isAuthenticated {
                    Button("Logout") {
                        authViewModel.signOut()
                    }
                }
            }
        }
    }
}

// AdminLoginView - Login UI
struct AdminLoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "lock.shield")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("Admin Login")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please enter your credentials")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                SecureField("Password", text: $password)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 30)
            
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            HStack {
                Text("Admin Email: admin@example.com")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Password: password123")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                authViewModel.signIn(email: email, password: password)
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(authViewModel.isLoading)
            
            Spacer()
            
            Text("Only authorized administrators can access this section")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .padding()
    }
}

// AdminDashboardView - Content shown after authentication
struct AdminDashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            Text("Tournament Management")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            // Placeholder for future admin features
            List {
                Section(header: Text("Team Management")) {
                    NavigationLink(destination: TeamApprovalsView()) {
                        HStack {
                            Image(systemName: "person.2.badge.gearshape")
                                .foregroundColor(.blue)
                            Text("Team Approvals")
                        }
                    }
                }
                
                Section(header: Text("Tournament Control")) {
                    NavigationLink(destination: AdminMatchUpdateView()) {
                        HStack {
                            Image(systemName: "trophy")
                                .foregroundColor(.orange)
                            Text("Update Match Results")
                        }
                    }
                }
                
                Section(header: Text("Communication")) {
                    NavigationLink(destination: AdminNotificationsView()) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.red)
                            Text("Send Notifications")
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
} 



