import Foundation
import FirebaseFirestore

class TournamentManager: ObservableObject {
    @Published var teams: [TeamData] = []
    private let db = Firestore.firestore()
    
    init() {
        loadTeams()
    }
    
    // Function to load all teams from Firestore
    func loadTeams() {
        print("📥 Loading teams from Firebase...")
        
        db.collection("teams").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error loading teams: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ No team documents found")
                return
            }
            
            print("✅ Successfully loaded \(documents.count) teams")
            
            let loadedTeams = documents.compactMap { document -> TeamData? in
                let data = document.data()
                
                guard let name = data["name"] as? String else {
                    print("⚠️ Could not parse team data for document \(document.documentID)")
                    return nil
                }
                
                return TeamData(id: document.documentID, name: name)
            }
            
            DispatchQueue.main.async {
                self?.teams = loadedTeams
            }
        }
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
        
        db.collection("teams").addDocument(data: teamData) { [weak self] error in
            if let error = error {
                print("❌ Error adding team to Firebase:", error.localizedDescription)
            } else {
                print("✅ Team successfully added to Firebase")
                DispatchQueue.main.async {
                    let teamData = TeamData(id: UUID().uuidString, name: team.name)
                    self?.teams.append(teamData)
                }
            }
        }
    }
}
