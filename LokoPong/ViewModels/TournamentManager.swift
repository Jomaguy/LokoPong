import Foundation
import FirebaseFirestore

class TournamentManager: ObservableObject {
    @Published var teams: [Team] = []
    private let db = Firestore.firestore()
    
    init() {
    }
    
    
    func addTeam(name: String, player1: String, player2: String, phone1: String, phone2: String) {
        print("📝 Starting team registration process...")
        print("Team details - Name: \(name), Players: \(player1), \(player2), Contacts: \(phone1), \(phone2)")
        
        let team = Team(
            name: name,
            player1Name: player1,
            player2Name: player2,
            contact1: phone1,
            contact2: phone2,
            registrationDate: Date(),
            isApproved: false
        )
        
        let teamData = [
            "name": team.name,
            "player1Name": team.player1Name,
            "player2Name": team.player2Name,
            "contact1": team.contact1,
            "contact2": team.contact2,
            "registrationDate": team.registrationDate,
            "isApproved": team.isApproved
        ] as [String : Any]
        
        print("💾 Attempting to save to Firebase:", teamData)
        
        db.collection("teams").addDocument(data: teamData) { error in
            if let error = error {
                print("❌ Error adding team to Firebase:", error.localizedDescription)
            } else {
                print("✅ Team successfully added to Firebase")
                DispatchQueue.main.async {
                    self.teams.append(team)
                }
            }
        }
    }
}
