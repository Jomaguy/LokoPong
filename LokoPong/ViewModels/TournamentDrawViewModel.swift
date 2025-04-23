import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

/**
 * TournamentDrawViewModel
 *
 * Purpose: Manages the tournament bracket system for the Loko Pong tournament.
 * - Handles data structures for matches and brackets
 * - Manages tournament progression
 * - Handles team pairing and bracket generation
 * - Interfaces with Firebase for data persistence
 */

// Represents a single match in the tournament
struct MatchData: Identifiable {
    let team1: String
    let team2: String
    let team1Score: Int = 0
    let team2Score: Int = 0
    
    // Player information for each team
    let team1Players: [String]
    let team2Players: [String]
    
    // Unique identifier for each match
    var id: String {
        team1 + team2
    }
}

// Represents a round in the tournament (e.g., "Quarter Finals")
struct Bracket {
    let name: String        // Name of the round (e.g., "First Round", "Semi Finals")
    let matches: [MatchData] // Array of matches in this round
}

class TournamentDrawViewModel: ObservableObject {
    @Published var brackets: [Bracket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let teamService = TeamService()
    
    // Default initializer
    init() {}
    
    // Initializer with predefined brackets for testing/preview
    init(brackets: [Bracket]) {
        self.brackets = brackets
    }
    
    func loadTournamentData() {
        isLoading = true
        
        teamService.fetchTeams { [weak self] teams in
            guard let self = self else { return }
            
            // Generate brackets with real team names
            self.generateBrackets(with: teams)
            self.isLoading = false
        }
    }
    
    private func generateBrackets(with teams: [TeamData]) {
        // Create a working copy of teams and pad with BYE entries if needed
        var tournamentTeams = teams
        
        // If we have fewer than 16 teams, add BYE placeholders
        if tournamentTeams.count < 16 {
            print("⚠️ Not enough teams (\(tournamentTeams.count)/16) - adding BYE placeholders")
            
            // Add BYE teams until we have 16
            for i in tournamentTeams.count..<16 {
                let byeTeam = TeamData(id: "bye-\(i)", name: "BYE")
                tournamentTeams.append(byeTeam)
            }
        }
        
        // Create brackets with actual team names + BYE teams
        let eightsBracket = Bracket(name: "Eights", matches: [
            createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1]),
            createMatch(team1: tournamentTeams[2], team2: tournamentTeams[3]),
            createMatch(team1: tournamentTeams[4], team2: tournamentTeams[5]),
            createMatch(team1: tournamentTeams[6], team2: tournamentTeams[7]),
            createMatch(team1: tournamentTeams[8], team2: tournamentTeams[9]),
            createMatch(team1: tournamentTeams[10], team2: tournamentTeams[11]),
            createMatch(team1: tournamentTeams[12], team2: tournamentTeams[13]),
            createMatch(team1: tournamentTeams[14], team2: tournamentTeams[15])
        ])
        
        // Determine winners based on BYE rules
        let quarterTeams = [
            getWinner(team1: tournamentTeams[0], team2: tournamentTeams[1]),
            getWinner(team1: tournamentTeams[2], team2: tournamentTeams[3]),
            getWinner(team1: tournamentTeams[4], team2: tournamentTeams[5]),
            getWinner(team1: tournamentTeams[6], team2: tournamentTeams[7]),
            getWinner(team1: tournamentTeams[8], team2: tournamentTeams[9]),
            getWinner(team1: tournamentTeams[10], team2: tournamentTeams[11]),
            getWinner(team1: tournamentTeams[12], team2: tournamentTeams[13]),
            getWinner(team1: tournamentTeams[14], team2: tournamentTeams[15])
        ]
        
        let quarterFinalsBracket = Bracket(name: "Quarter Finals", matches: [
            createMatch(team1: quarterTeams[0], team2: quarterTeams[1]),
            createMatch(team1: quarterTeams[2], team2: quarterTeams[3]),
            createMatch(team1: quarterTeams[4], team2: quarterTeams[5]),
            createMatch(team1: quarterTeams[6], team2: quarterTeams[7])
        ])
        
        let semiTeams = [
            getWinner(team1: quarterTeams[0], team2: quarterTeams[1]),
            getWinner(team1: quarterTeams[2], team2: quarterTeams[3]),
            getWinner(team1: quarterTeams[4], team2: quarterTeams[5]),
            getWinner(team1: quarterTeams[6], team2: quarterTeams[7])
        ]
        
        let semiFinalsBracket = Bracket(name: "Semi Finals", matches: [
            createMatch(team1: semiTeams[0], team2: semiTeams[1]),
            createMatch(team1: semiTeams[2], team2: semiTeams[3])
        ])
        
        let finalTeams = [
            getWinner(team1: semiTeams[0], team2: semiTeams[1]),
            getWinner(team1: semiTeams[2], team2: semiTeams[3])
        ]
        
        let finalsBracket = Bracket(name: "Grand Finals", matches: [
            createMatch(team1: finalTeams[0], team2: finalTeams[1])
        ])
        
        DispatchQueue.main.async {
            self.brackets = [eightsBracket, quarterFinalsBracket, semiFinalsBracket, finalsBracket]
        }
    }
    
    // Helper method to create a match without scores
    private func createMatch(team1: TeamData, team2: TeamData) -> MatchData {
        return MatchData(
            team1: team1.name, 
            team2: team2.name,
            team1Players: team1.players,
            team2Players: team2.players
        )
    }
    
    // Helper method to determine which team advances to the next round
    private func getWinner(team1: TeamData, team2: TeamData) -> TeamData {
        // If team1 is BYE, team2 advances
        if team1.name == "BYE" {
            return team2
        }
        // If team2 is BYE, team1 advances
        else if team2.name == "BYE" {
            return team1
        }
        // If neither is BYE, use random selection (in real app would use match results)
        else {
            return Bool.random() ? team1 : team2
        }
    }
    
    // Helper method to determine match scores when BYE teams are involved
    private func calculateScores(team1: TeamData, team2: TeamData) -> (Int, Int) {
        if team1.name == "BYE" && team2.name == "BYE" {
            return (0, 0) // Both BYE
        } else if team1.name == "BYE" {
            return (0, 3) // Team 2 wins by default
        } else if team2.name == "BYE" {
            return (3, 0) // Team 1 wins by default
        } else {
            // Randomly determine a winner for actual teams (could be replaced with real scores)
            let team1Score = Int.random(in: 0...3)
            let team2Score = team1Score >= 3 ? Int.random(in: 0...2) : 3
            return (team1Score, team2Score)
        }
    }
}
