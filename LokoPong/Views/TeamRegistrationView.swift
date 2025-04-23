import SwiftUI

struct TeamRegistrationView: View {
    @EnvironmentObject var tournamentManager: TournamentManager
    @State private var teamName = ""
    @State private var player1Name = ""
    @State private var player2Name = ""
    @State private var contact1 = ""
    @State private var contact2 = ""
    @State private var navigateToConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("LokoPong Team Registration")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
                
                Section(header: Text("Team Information")) {
                    TextField("Team Name", text: $teamName)
                }
                
                Section(header: Text("Players")) {
                    TextField("Player 1 Name", text: $player1Name)
                    TextField("Player 2 Name", text: $player2Name)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Contact 1", text: $contact1)
                        .keyboardType(.phonePad)
                    TextField("Contact 2", text: $contact2)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    NavigationLink(destination: ConfirmationView(), isActive: $navigateToConfirmation) {
                        EmptyView()
                    }
                    
                    Button {
                        print("🔘 Register button pressed")
                        tournamentManager.addTeam(
                            name: teamName,
                            player1: player1Name,
                            player2: player2Name,
                            phone1: contact1,
                            phone2: contact2
                        )
                        navigateToConfirmation = true
                    } label: {
                        Text("Register Team")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Team Registration")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !teamName.isEmpty &&
        !player1Name.isEmpty &&
        !player2Name.isEmpty &&
        !contact1.isEmpty &&
        !contact2.isEmpty
    }
}

struct ConfirmationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Your submission has been received")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("We will notify you once we have reviewed it and added you to the draw")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
    }
}
