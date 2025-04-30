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
    
    // Unique identifier for each match (automatically generated)
    let uniqueId: String
    
    // Unique identifier for each match
    var id: String {
        uniqueId
    }
    
    init(team1: String, team2: String, team1Players: [String], team2Players: [String], uniqueId: String = UUID().uuidString) {
        self.team1 = team1
        self.team2 = team2
        self.team1Players = team1Players
        self.team2Players = team2Players
        self.uniqueId = uniqueId
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
        errorMessage = nil
        
        // Use approved teams only for tournament brackets
        teamService.fetchApprovedTeams { [weak self] teams in
            guard let self = self else { return }
            
            if teams.isEmpty {
                self.errorMessage = "No approved teams available for tournament"
                self.isLoading = false
                return
            }
            
            // Generate brackets with approved team names
            self.generateBrackets(with: teams)
            self.isLoading = false
        }
    }
    
    // Also add an async version for potential future use
    func loadTournamentDataAsync() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let approvedTeams = try await teamService.fetchApprovedTeamsAsync()
            
            if approvedTeams.isEmpty {
                DispatchQueue.main.async {
                    self.errorMessage = "No approved teams available for tournament"
                    self.isLoading = false
                }
                return
            }
            
            // Generate brackets with approved teams
            generateBrackets(with: approvedTeams)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load tournament data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func generateBrackets(with teams: [TeamData]) {
        // Create a working copy of teams
        let actualTeams = teams
        
        // Determine the optimal bracket size based on the number of teams
        let bracketSize = determineBracketSize(teamCount: actualTeams.count)
        print("🏆 Creating tournament bracket with \(bracketSize) slots for \(actualTeams.count) teams")
        
        // Distribute teams and BYEs evenly throughout the bracket
        let tournamentTeams = distributeTeamsAndByes(teams: actualTeams, bracketSize: bracketSize)
        
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
        
        // Calculate the number of rounds (log base 2 of bracketSize)
        let numberOfRounds = Int(log2(Double(bracketSize)))
        
        // Generate each round
        for round in 0..<numberOfRounds {
            let roundName = getRoundName(roundIndex: round, totalRounds: numberOfRounds)
            
            // Only create actual matches for the first round
            if round == 0 {
                // First round - create matches with actual teams
                var roundMatches: [MatchData] = []
                let matchesInRound = bracketSize / 2
                
                for i in 0..<matchesInRound {
                    let team1Index = i * 2
                    let team2Index = i * 2 + 1
                    
                    if team1Index < tournamentTeams.count && team2Index < tournamentTeams.count {
                        roundMatches.append(createMatch(team1: tournamentTeams[team1Index], team2: tournamentTeams[team2Index]))
                    }
                }
                
                // Add this round's bracket to all brackets
                allBrackets.append(Bracket(name: roundName, matches: roundMatches))
            } else {
                // Subsequent rounds - create empty brackets with placeholder matches
                // The number of matches in this round is half the number in the previous round
                let matchesInRound = bracketSize / Int(pow(2.0, Double(round + 1)))
                
                // Create empty placeholder matches for this round
                let emptyMatches = (0..<matchesInRound).map { _ in
                    return createEmptyMatch()
                }
                
                allBrackets.append(Bracket(name: roundName, matches: emptyMatches))
            }
        }
        
        // Update the UI on the main thread
        DispatchQueue.main.async {
            self.brackets = allBrackets
        }
    }
    
    // Helper method to distribute teams and BYEs evenly throughout the bracket
    private func distributeTeamsAndByes(teams: [TeamData], bracketSize: Int) -> [TeamData] {
        // Number of BYEs needed
        let byeCount = bracketSize - teams.count
        
        // If no BYEs needed, return the teams as is
        if byeCount <= 0 {
            return teams
        }
        
        print("⚠️ Adding \(byeCount) BYEs distributed optimally throughout the bracket")
        
        // Create an array to represent positions in the bracket
        // true = BYE, false = real team
        var isByePosition = [Bool](repeating: false, count: bracketSize)
        
        // Distribute BYEs optimally using a power-of-2 pattern
        // This ensures BYEs don't face each other in the first round
        distributeByes(isByePosition: &isByePosition, startIdx: 0, endIdx: bracketSize - 1, 
                       byesRemaining: byeCount, bracketSize: bracketSize)
        
        // Now create the resulting array with teams and BYEs properly positioned
        var result = [TeamData]()
        var teamIndex = 0
        
        for i in 0..<bracketSize {
            if isByePosition[i] {
                // This position gets a BYE
                result.append(TeamData(id: "bye-\(i)", name: "BYE"))
            } else if teamIndex < teams.count {
                // This position gets a real team
                result.append(teams[teamIndex])
                teamIndex += 1
            }
        }
        
        return result
    }
    
    // Helper method to recursively distribute BYEs optimally throughout the bracket
    private func distributeByes(isByePosition: inout [Bool], startIdx: Int, endIdx: Int, 
                               byesRemaining: Int, bracketSize: Int) {
        // Base case: no more BYEs to distribute
        if byesRemaining <= 0 {
            return
        }
        
        // Base case: only one position to consider
        if startIdx == endIdx {
            if byesRemaining > 0 {
                isByePosition[startIdx] = true
            }
            return
        }
        
        // Calculate the size of this sub-bracket
        let size = endIdx - startIdx + 1
        
        // For optimal distribution in a tournament, BYEs should be placed
        // in a pattern that ensures they don't play each other in round 1
        
        // If we have enough BYEs for half of the sub-bracket
        if byesRemaining >= size / 2 {
            // Create a mutable copy of byesRemaining
            var remainingByes = byesRemaining
            
            // Fill every other position with BYEs
            for i in stride(from: startIdx + 1, through: endIdx, by: 2) {
                if remainingByes > 0 {
                    isByePosition[i] = true
                    remainingByes -= 1
                }
            }
            
            // Then distribute remaining BYEs in the other positions
            for i in stride(from: startIdx, through: endIdx, by: 2) {
                if remainingByes > 0 && !isByePosition[i] {
                    isByePosition[i] = true
                    remainingByes -= 1
                }
            }
        } else {
            // Not enough BYEs for half the bracket, so distribute evenly
            let midIdx = startIdx + (size / 2)
            
            // Recursively distribute BYEs in the first half
            let firstHalfByes = byesRemaining / 2
            if firstHalfByes > 0 {
                distributeByes(isByePosition: &isByePosition, 
                              startIdx: startIdx, 
                              endIdx: midIdx - 1, 
                              byesRemaining: firstHalfByes, 
                              bracketSize: bracketSize)
            }
            
            // Recursively distribute BYEs in the second half
            let secondHalfByes = byesRemaining - firstHalfByes
            if secondHalfByes > 0 {
                distributeByes(isByePosition: &isByePosition, 
                              startIdx: midIdx, 
                              endIdx: endIdx, 
                              byesRemaining: secondHalfByes, 
                              bracketSize: bracketSize)
            }
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
            team2Players: team2.players,
            uniqueId: UUID().uuidString
        )
    }
    
    // Helper method to create an empty match for future rounds
    private func createEmptyMatch() -> MatchData {
        return MatchData(
            team1: "TBD", 
            team2: "TBD",
            team1Players: [],
            team2Players: [],
            uniqueId: UUID().uuidString
        )
    }
}
