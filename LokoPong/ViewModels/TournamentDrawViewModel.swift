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
        // Create a working copy of teams
        var tournamentTeams = teams
        
        // Determine the optimal bracket size based on the number of teams
        let bracketSize = determineBracketSize(teamCount: tournamentTeams.count)
        print("🏆 Creating tournament bracket with \(bracketSize) slots for \(tournamentTeams.count) teams")
        
        // Pad with BYE entries if needed
        if tournamentTeams.count < bracketSize {
            print("⚠️ Not enough teams (\(tournamentTeams.count)/\(bracketSize)) - adding BYE placeholders")
            
            // Add BYE teams until we reach the bracket size
            for i in tournamentTeams.count..<bracketSize {
                let byeTeam = TeamData(id: "bye-\(i)", name: "BYE")
                tournamentTeams.append(byeTeam)
            }
        }
        
        // Generate brackets based on the bracket size
        var allBrackets: [Bracket] = []
        
        // First round (could be Eights, Quarter Finals, Semi Finals, or Grand Finals depending on bracket size)
        var firstRoundMatches: [MatchData] = []
        var firstRoundName = ""
        
        // Set up the first round based on bracket size
        switch bracketSize {
        case 16:
            firstRoundName = "Eights"
            firstRoundMatches = [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1]),
                createMatch(team1: tournamentTeams[2], team2: tournamentTeams[3]),
                createMatch(team1: tournamentTeams[4], team2: tournamentTeams[5]),
                createMatch(team1: tournamentTeams[6], team2: tournamentTeams[7]),
                createMatch(team1: tournamentTeams[8], team2: tournamentTeams[9]),
                createMatch(team1: tournamentTeams[10], team2: tournamentTeams[11]),
                createMatch(team1: tournamentTeams[12], team2: tournamentTeams[13]),
                createMatch(team1: tournamentTeams[14], team2: tournamentTeams[15])
            ]
        case 8:
            firstRoundName = "Quarter Finals"
            firstRoundMatches = [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1]),
                createMatch(team1: tournamentTeams[2], team2: tournamentTeams[3]),
                createMatch(team1: tournamentTeams[4], team2: tournamentTeams[5]),
                createMatch(team1: tournamentTeams[6], team2: tournamentTeams[7])
            ]
        case 4:
            firstRoundName = "Semi Finals"
            firstRoundMatches = [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1]),
                createMatch(team1: tournamentTeams[2], team2: tournamentTeams[3])
            ]
        case 2:
            // For 2 teams, we go directly to the finals
            firstRoundName = "Grand Finals"
            firstRoundMatches = [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1])
            ]
            
            // Add finals and exit early since we don't need to generate more rounds
            allBrackets.append(Bracket(name: firstRoundName, matches: firstRoundMatches))
            DispatchQueue.main.async {
                self.brackets = allBrackets
            }
            return
        default:
            print("❌ Invalid bracket size: \(bracketSize)")
            return
        }
        
        // Add first round to brackets
        allBrackets.append(Bracket(name: firstRoundName, matches: firstRoundMatches))
        
        // Process first round to get teams for the next round
        var currentRoundTeams = tournamentTeams
        var nextRoundTeams: [TeamData] = []
        
        // Generate subsequent rounds based on bracket size
        if bracketSize >= 8 { // For 8 or 16 team brackets, we need Quarter Finals
            if bracketSize == 16 {
                // Quarter Finals for 16-team bracket
                nextRoundTeams = [
                    getWinner(team1: currentRoundTeams[0], team2: currentRoundTeams[1]),
                    getWinner(team1: currentRoundTeams[2], team2: currentRoundTeams[3]),
                    getWinner(team1: currentRoundTeams[4], team2: currentRoundTeams[5]),
                    getWinner(team1: currentRoundTeams[6], team2: currentRoundTeams[7]),
                    getWinner(team1: currentRoundTeams[8], team2: currentRoundTeams[9]),
                    getWinner(team1: currentRoundTeams[10], team2: currentRoundTeams[11]),
                    getWinner(team1: currentRoundTeams[12], team2: currentRoundTeams[13]),
                    getWinner(team1: currentRoundTeams[14], team2: currentRoundTeams[15])
                ]
                
                let quarterFinalsBracket = Bracket(name: "Quarter Finals", matches: [
                    createMatch(team1: nextRoundTeams[0], team2: nextRoundTeams[1]),
                    createMatch(team1: nextRoundTeams[2], team2: nextRoundTeams[3]),
                    createMatch(team1: nextRoundTeams[4], team2: nextRoundTeams[5]),
                    createMatch(team1: nextRoundTeams[6], team2: nextRoundTeams[7])
                ])
                
                allBrackets.append(quarterFinalsBracket)
                currentRoundTeams = nextRoundTeams
            }
            
            // Semi Finals for 8 or 16-team brackets
            if bracketSize == 8 {
                nextRoundTeams = [
                    getWinner(team1: currentRoundTeams[0], team2: currentRoundTeams[1]),
                    getWinner(team1: currentRoundTeams[2], team2: currentRoundTeams[3]),
                    getWinner(team1: currentRoundTeams[4], team2: currentRoundTeams[5]),
                    getWinner(team1: currentRoundTeams[6], team2: currentRoundTeams[7])
                ]
            } else { // 16-team bracket - same calculation but already done in the Quarter Finals step
                // No need to recalculate - nextRoundTeams was already populated in the Quarter Finals section
            }
            
            let semiFinalsBracket = Bracket(name: "Semi Finals", matches: [
                createMatch(team1: nextRoundTeams[0], team2: nextRoundTeams[1]),
                createMatch(team1: nextRoundTeams[2], team2: nextRoundTeams[3])
            ])
            
            allBrackets.append(semiFinalsBracket)
            currentRoundTeams = nextRoundTeams
        }
        
        // Final round for all bracket sizes
        // For 4, 8, and 16-team brackets, we need the final match between the winners of the previous round
        let finalTeams = [
            getWinner(team1: currentRoundTeams[0], team2: currentRoundTeams[1]),
            getWinner(team1: currentRoundTeams[2], team2: currentRoundTeams[3])
        ]
        
        let finalsBracket = Bracket(name: "Grand Finals", matches: [
            createMatch(team1: finalTeams[0], team2: finalTeams[1])
        ])
        
        allBrackets.append(finalsBracket)
        
        // Update the UI on the main thread
        DispatchQueue.main.async {
            self.brackets = allBrackets
        }
    }
    
    // Helper method to determine the optimal bracket size
    private func determineBracketSize(teamCount: Int) -> Int {
        if teamCount <= 2 {
            return 2 // 1 round: Grand Finals only
        } else if teamCount <= 4 {
            return 4 // 2 rounds: Semi Finals, Finals
        } else if teamCount <= 8 {
            return 8 // 3 rounds: Quarter Finals, Semi Finals, Finals
        } else {
            return 16 // 4 rounds: Eights, Quarter Finals, Semi Finals, Finals
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
