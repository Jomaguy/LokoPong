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
        
        // Generate brackets dynamically based on the bracket size
        var allBrackets: [Bracket] = []
        
        // Special case for 2 teams
        if bracketSize == 2 {
            // For 2 teams, we go directly to the finals
            let finalsBracket = Bracket(name: "Grand Finals", matches: [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1])
            ])
            
            allBrackets.append(finalsBracket)
            DispatchQueue.main.async {
                self.brackets = allBrackets
            }
            return
        }
        
        // For larger brackets, generate rounds dynamically
        var roundTeams = tournamentTeams
        var currentRoundSize = bracketSize
        
        // Calculate the number of rounds (log base 2 of bracketSize)
        let numberOfRounds = Int(log2(Double(bracketSize)))
        
        // Generate each round, starting from the first round
        for round in 0..<numberOfRounds {
            let isLastRound = round == numberOfRounds - 1
            let roundName = getRoundName(roundIndex: round, totalRounds: numberOfRounds)
            
            // Create matches for this round
            var roundMatches: [MatchData] = []
            let matchesInRound = currentRoundSize / 2
            
            for i in 0..<matchesInRound {
                let team1Index = i * 2
                let team2Index = i * 2 + 1
                
                if team1Index < roundTeams.count && team2Index < roundTeams.count {
                    roundMatches.append(createMatch(team1: roundTeams[team1Index], team2: roundTeams[team2Index]))
                }
            }
            
            // Add this round's bracket to all brackets
            allBrackets.append(Bracket(name: roundName, matches: roundMatches))
            
            // If this is the last round, we're done
            if isLastRound {
                break
            }
            
            // Determine winners for the next round
            var nextRoundTeams: [TeamData] = []
            for i in 0..<matchesInRound {
                let team1Index = i * 2
                let team2Index = i * 2 + 1
                
                if team1Index < roundTeams.count && team2Index < roundTeams.count {
                    let winner = getWinner(team1: roundTeams[team1Index], team2: roundTeams[team2Index])
                    nextRoundTeams.append(winner)
                }
            }
            
            // Update for next round
            roundTeams = nextRoundTeams
            currentRoundSize = currentRoundSize / 2
        }
        
        // Update the UI on the main thread
        DispatchQueue.main.async {
            self.brackets = allBrackets
        }
    }
    
    // Helper method to determine the optimal bracket size (next power of 2)
    private func determineBracketSize(teamCount: Int) -> Int {
        if teamCount <= 0 {
            return 2 // Minimum size is 2
        }
        
        // Find the next power of 2 that is >= teamCount
        var power = 1
        while power < teamCount {
            power *= 2
        }
        
        return power
    }
    
    // Helper method to determine round name based on the round index
    private func getRoundName(roundIndex: Int, totalRounds: Int) -> String {
        // The last round is always the Grand Finals
        if roundIndex == totalRounds - 1 {
            return "Grand Finals"
        }
        
        // The second-to-last round is always the Semi Finals
        if roundIndex == totalRounds - 2 {
            return "Semi Finals"
        }
        
        // The third-to-last round is always the Quarter Finals
        if roundIndex == totalRounds - 3 {
            return "Quarter Finals"
        }
        
        // For earlier rounds, use a naming convention based on the number of teams
        let teamsInRound = Int(pow(2.0, Double(totalRounds - roundIndex)))
        
        switch teamsInRound {
        case 16:
            return "Eights"
        case 32:
            return "Round of 32"
        case 64:
            return "Round of 64"
        case 128:
            return "Round of 128"
        case 256:
            return "Round of 256"
        default:
            return "Round \(roundIndex + 1)"
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
