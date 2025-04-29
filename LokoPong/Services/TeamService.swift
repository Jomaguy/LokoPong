//
//  TeamService.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

import Foundation
import FirebaseFirestore

/**
 * TeamData
 *
 * Model representing a team in the tournament.
 */
struct TeamData: Identifiable {
    let id: String
    let name: String
    let players: [String]
    
    // Initializer with default empty players array for backward compatibility
    init(id: String, name: String, players: [String] = []) {
        self.id = id
        self.name = name
        self.players = players
    }
}

/**
 * TeamService
 *
 * Service class for managing team-related operations.
 * Handles interactions with Firestore database for team data.
 */
class TeamService {
    private let db = Firestore.firestore()
    
    // Fetch teams asynchronously using async/await
    func fetchTeamsAsync() async throws -> [TeamData] {
        let snapshot = try await db.collection("teams").getDocuments()
        let teams = snapshot.documents.compactMap { document -> TeamData? in
            let data = document.data()
            guard let name = data["name"] as? String else { 
                print("⚠️ Missing name field in team document \(document.documentID)")
                return nil 
            }
            
            // Extract individual player names from Firebase structure
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
            
            // Debug log player information
            print("📊 Team '\(name)' has \(players.isEmpty ? "NO" : "\(players.count)") players: \(players)")
            
            return TeamData(id: document.documentID, name: name, players: players)
        }
        
        if teams.isEmpty {
            print("⚠️ No valid teams found - creating dummy data for testing")
            // Create dummy teams if none found in Firestore (for testing)
            return (1...16).map { index in
                // Create sample player names for each team
                let dummyPlayers = [
                    "Player \(index)A",
                    "Player \(index)B"
                ]
                print("🔄 Creating dummy team: Team \(index) with players: \(dummyPlayers)")
                return TeamData(id: "team\(index)", name: "Team \(index)", players: dummyPlayers)
            }
        }
        
        print("✅ Returning \(teams.count) teams")
        return teams
    }
    
    // Legacy completion handler version
    func fetchTeams(completion: @escaping ([TeamData]) -> Void) {
        db.collection("teams").getDocuments { snapshot, error in
            guard error == nil else {
                print("❌ Error fetching teams: \(error!.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ No team documents found")
                completion([])
                return
            }
            
            print("✅ Successfully loaded \(documents.count) teams from TeamService")
            
            let teams = documents.compactMap { document -> TeamData? in
                let data = document.data()
                guard let name = data["name"] as? String else { 
                    print("⚠️ Missing name field in team document \(document.documentID)")
                    return nil 
                }
                
                // Extract individual player names from Firebase structure
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
                
                // Debug log player information
                print("📊 Team '\(name)' has \(players.isEmpty ? "NO" : "\(players.count)") players: \(players)")
                
                return TeamData(id: document.documentID, name: name, players: players)
            }
            
            if teams.isEmpty {
                print("⚠️ No valid teams found - creating dummy data for testing")
                // Create dummy teams if none found in Firestore (for testing)
                let dummyTeams = (1...16).map { index in
                    // Create sample player names for each team
                    let dummyPlayers = [
                        "Player \(index)A",
                        "Player \(index)B"
                    ]
                    print("🔄 Creating dummy team: Team \(index) with players: \(dummyPlayers)")
                    return TeamData(id: "team\(index)", name: "Team \(index)", players: dummyPlayers)
                }
                completion(dummyTeams)
            } else {
                print("✅ Returning \(teams.count) teams")
                completion(teams)
            }
        }
    }
} 