import SwiftUI
import FirebaseAuth

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
    }
} 