import Foundation
import FirebaseFirestore
import SwiftUI
import Combine
import Firebase

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
    // Removed team score fields as they're not needed
    
    // Player information for each team
    let team1Players: [String]
    let team2Players: [String]
    
    // Winner of the match (either team1 or team2 name, or empty if not yet decided)
    var winner: String = ""
    
    // Unique identifier for each match (automatically generated)
    let uniqueId: String
    
    // Unique identifier for each match
    var id: String {
        uniqueId
    }
    
    init(team1: String, team2: String, team1Players: [String], team2Players: [String], winner: String = "", uniqueId: String = UUID().uuidString) {
        self.team1 = team1
        self.team2 = team2
        self.team1Players = team1Players
        self.team2Players = team2Players
        self.winner = winner
        self.uniqueId = uniqueId
    }
}

// Represents a round in the tournament (e.g., "Quarter Finals")
struct Bracket: Identifiable {
    let id: String
    let name: String        // Name of the round (e.g., "First Round", "Semi Finals")
    let matches: [MatchData] // Array of matches in this round
    
    init(id: String = UUID().uuidString, name: String, matches: [MatchData]) {
        self.id = id
        self.name = name
        self.matches = matches
    }
}

class TournamentDrawViewModel: ObservableObject {
    @Published var brackets: [Bracket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentTournamentID: String?
    
    private let teamService = TeamService()
    private var tournamentListeners: [ListenerRegistration] = []
    
    // Default initializer
    init() {}
    
    // Initializer with predefined brackets for testing/preview
    init(brackets: [Bracket]) {
        self.brackets = brackets
    }
    
    deinit {
        // Remove all listeners when the view model is deallocated
        removeAllListeners()
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
    
    // Function to load tournament data from Firestore
    func loadTournamentFromFirestore() {
        isLoading = true
        errorMessage = nil
        
        // Remove any existing listeners
        removeAllListeners()
        
        // Try to get the current tournament ID
        guard let tournamentID = currentTournamentID ?? UserDefaults.standard.string(forKey: "currentTournamentID") else {
            // No tournament found, we need to create one
            loadTournamentData() // This will generate and save to Firestore
            return
        }
        
        let db = Firestore.firestore()
        let tournamentRef = db.collection("tournaments").document(tournamentID)
        
        // Check if tournament exists
        tournamentRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error loading tournament: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("⚠️ Tournament not found, creating a new one")
                self.loadTournamentData() // This will generate and save to Firestore
                return
            }
            
            // Tournament exists, set up real-time listeners
            self.setupTournamentListeners(tournamentID: tournamentID)
        }
    }
    
    // Setup real-time listeners for tournament updates
    private func setupTournamentListeners(tournamentID: String) {
        let db = Firestore.firestore()
        let tournamentRef = db.collection("tournaments").document(tournamentID)
        
        // Listen for bracket changes
        let bracketsListener = tournamentRef.collection("brackets").order(by: "roundIndex")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error listening for bracket updates: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No brackets found")
                    return
                }
                
                // Process bracket documents
                self.processBracketDocuments(documents, tournamentID: tournamentID)
            }
        
        // Store the listener for later removal
        tournamentListeners.append(bracketsListener)
    }
    
    // Process bracket documents and set up match listeners
    private func processBracketDocuments(_ documents: [QueryDocumentSnapshot], tournamentID: String) {
        let db = Firestore.firestore()
        let tournamentRef = db.collection("tournaments").document(tournamentID)
        
        var loadedBrackets: [Bracket] = []
        let group = DispatchGroup()
        
        // Process each bracket
        for bracketDoc in documents {
            group.enter()
            
            let bracketData = bracketDoc.data()
            let bracketName = bracketData["name"] as? String ?? "Unknown Round"
            let bracketId = bracketDoc.documentID
            
            // Set up listener for matches in this bracket
            let matchesListener = bracketDoc.reference.collection("matches")
                .addSnapshotListener { [weak self] (matchesSnapshot, matchError) in
                    guard let self = self else { return }
                    
                    if let matchError = matchError {
                        print("❌ Error listening for match updates: \(matchError.localizedDescription)")
                        return
                    }
                    
                    var matches: [MatchData] = []
                    
                    // Process each match
                    for matchDoc in matchesSnapshot?.documents ?? [] {
                        let matchData = matchDoc.data()
                        
                        let match = MatchData(
                            team1: matchData["team1"] as? String ?? "Unknown",
                            team2: matchData["team2"] as? String ?? "Unknown",
                            team1Players: matchData["team1Players"] as? [String] ?? [],
                            team2Players: matchData["team2Players"] as? [String] ?? [],
                            winner: matchData["winner"] as? String ?? "",
                            uniqueId: matchDoc.documentID
                        )
                        
                        matches.append(match)
                    }
                    
                    // Update or create bracket with the latest matches
                    let updatedBracket = Bracket(
                        id: bracketId,
                        name: bracketName,
                        matches: matches
                    )
                    
                    // Update brackets array on main thread
                    DispatchQueue.main.async {
                        if let existingIndex = self.brackets.firstIndex(where: { $0.id == bracketId }) {
                            // Update existing bracket
                            self.brackets[existingIndex] = updatedBracket
                        } else {
                            // Add new bracket
                            self.brackets.append(updatedBracket)
                            
                            // Sort brackets by roundIndex
                            self.brackets.sort { bracket1, bracket2 in
                                guard let index1 = documents.firstIndex(where: { $0.documentID == bracket1.id }),
                                      let index2 = documents.firstIndex(where: { $0.documentID == bracket2.id }) else {
                                    return false
                                }
                                return index1 < index2
                            }
                        }
                    }
                }
            
            // Store the listener
            tournamentListeners.append(matchesListener)
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.currentTournamentID = tournamentID
            self.isLoading = false
            print("✅ Tournament listeners set up successfully")
        }
    }
    
    // Remove all listeners when they're no longer needed
    private func removeAllListeners() {
        for listener in tournamentListeners {
            listener.remove()
        }
        tournamentListeners.removeAll()
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
            let finalsBracket = Bracket(id: UUID().uuidString, name: "Grand Finals", matches: [
                createMatch(team1: tournamentTeams[0], team2: tournamentTeams[1])
            ])
            
            allBrackets.append(finalsBracket)
            DispatchQueue.main.async {
                self.brackets = allBrackets
                // Save the generated brackets to Firestore
                self.saveTournamentToFirestore()
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
                        let team1 = tournamentTeams[team1Index]
                        let team2 = tournamentTeams[team2Index]
                        
                        // Check if either team is a BYE and set the winner accordingly
                        var match = createMatch(team1: team1, team2: team2)
                        
                        // If team1 is BYE, team2 is the winner
                        if team1.name.lowercased() == "bye" {
                            match.winner = team2.name
                        } 
                        // If team2 is BYE, team1 is the winner
                        else if team2.name.lowercased() == "bye" {
                            match.winner = team1.name
                        }
                        
                        roundMatches.append(match)
                    }
                }
                
                // Add this round's bracket to all brackets
                allBrackets.append(Bracket(id: UUID().uuidString, name: roundName, matches: roundMatches))
            } else {
                // Subsequent rounds - create empty brackets with placeholder matches
                // The number of matches in this round is half the number in the previous round
                let matchesInRound = bracketSize / Int(pow(2.0, Double(round + 1)))
                
                // Create empty placeholder matches for this round
                let emptyMatches = (0..<matchesInRound).map { _ in
                    return createEmptyMatch()
                }
                
                allBrackets.append(Bracket(id: UUID().uuidString, name: roundName, matches: emptyMatches))
            }
        }
        
        // Now propagate winners from BYE matches to the next round
        if allBrackets.count > 1 {
            let firstRoundMatches = allBrackets[0].matches
            var secondRoundMatches = allBrackets[1].matches
            
            for (matchIndex, match) in firstRoundMatches.enumerated() {
                if match.winner.isEmpty == false {
                    // This match has a pre-determined winner (BYE match)
                    let nextRoundMatchIndex = matchIndex / 2
                    
                    // Make sure we have a valid match index for the next round
                    if nextRoundMatchIndex < secondRoundMatches.count {
                        let isFirstMatchOfPair = matchIndex % 2 == 0
                        let winnerPlayers = match.team1 == match.winner ? match.team1Players : match.team2Players
                        
                        if isFirstMatchOfPair {
                            // Update team1 in the next round
                            secondRoundMatches[nextRoundMatchIndex] = MatchData(
                                team1: match.winner,
                                team2: secondRoundMatches[nextRoundMatchIndex].team2,
                                team1Players: winnerPlayers,
                                team2Players: secondRoundMatches[nextRoundMatchIndex].team2Players,
                                winner: secondRoundMatches[nextRoundMatchIndex].winner,
                                uniqueId: secondRoundMatches[nextRoundMatchIndex].uniqueId
                            )
                        } else {
                            // Update team2 in the next round
                            secondRoundMatches[nextRoundMatchIndex] = MatchData(
                                team1: secondRoundMatches[nextRoundMatchIndex].team1,
                                team2: match.winner,
                                team1Players: secondRoundMatches[nextRoundMatchIndex].team1Players,
                                team2Players: winnerPlayers,
                                winner: secondRoundMatches[nextRoundMatchIndex].winner,
                                uniqueId: secondRoundMatches[nextRoundMatchIndex].uniqueId
                            )
                        }
                    }
                }
            }
            
            // Update the second round bracket with the propagated winners
            allBrackets[1] = Bracket(
                id: allBrackets[1].id,
                name: allBrackets[1].name,
                matches: secondRoundMatches
            )
        }
        
        // Update the UI on the main thread
        DispatchQueue.main.async {
            self.brackets = allBrackets
            // Save the generated brackets to Firestore
            self.saveTournamentToFirestore()
        }
    }
    
    // Function to save the generated tournament to Firestore
    func saveTournamentToFirestore() {
        let db = Firestore.firestore()
        let tournamentID = UUID().uuidString
        self.currentTournamentID = tournamentID
        
        let tournamentRef = db.collection("tournaments").document(tournamentID)
        
        // Save tournament metadata
        tournamentRef.setData([
            "createdAt": FieldValue.serverTimestamp(),
            "status": "active"
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to save tournament: \(error.localizedDescription)"
                return
            }
            
            print("🏆 Created tournament with ID: \(tournamentID)")
            
            // Save each bracket
            let group = DispatchGroup()
            
            for (index, bracket) in self.brackets.enumerated() {
                group.enter()
                
                let bracketRef = tournamentRef.collection("brackets").document(bracket.id)
                bracketRef.setData([
                    "name": bracket.name,
                    "roundIndex": index
                ]) { error in
                    if let error = error {
                        print("❌ Error saving bracket: \(error.localizedDescription)")
                    }
                    
                    // Save each match in the bracket
                    let matchGroup = DispatchGroup()
                    
                    for match in bracket.matches {
                        matchGroup.enter()
                        
                        let matchData: [String: Any] = [
                            "team1": match.team1,
                            "team2": match.team2,
                            "team1Players": match.team1Players,
                            "team2Players": match.team2Players,
                            "winner": match.winner
                        ]
                        
                        bracketRef.collection("matches").document(match.id).setData(matchData) { error in
                            if let error = error {
                                print("❌ Error saving match: \(error.localizedDescription)")
                            }
                            matchGroup.leave()
                        }
                    }
                    
                    matchGroup.notify(queue: .main) {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("✅ Tournament draw saved to Firestore successfully")
                
                // Store the current tournament ID for reference
                UserDefaults.standard.set(tournamentID, forKey: "currentTournamentID")
            }
        }
    }
    
    // Function to update match winner in Firestore
    func updateMatchWinner(bracketId: String, matchId: String, winner: String) {
        // Get current tournament ID
        guard let tournamentID = self.currentTournamentID ?? UserDefaults.standard.string(forKey: "currentTournamentID") else {
            self.errorMessage = "No active tournament found"
            return
        }
        
        // Update local state first for immediate UI response
        if let bracketIndex = brackets.firstIndex(where: { $0.id == bracketId }),
           let matchIndex = brackets[bracketIndex].matches.firstIndex(where: { $0.id == matchId }) {
            
            // Create updated match with winner
            let match = brackets[bracketIndex].matches[matchIndex]
            let updatedMatch = MatchData(
                team1: match.team1,
                team2: match.team2,
                team1Players: match.team1Players,
                team2Players: match.team2Players,
                winner: winner,
                uniqueId: match.id
            )
            
            // Update brackets array
            var updatedMatches = brackets[bracketIndex].matches
            updatedMatches[matchIndex] = updatedMatch
            
            let updatedBracket = Bracket(
                id: brackets[bracketIndex].id,
                name: brackets[bracketIndex].name,
                matches: updatedMatches
            )
            
            // Update the published brackets array
            brackets[bracketIndex] = updatedBracket
        }
        
        // Then update Firestore
        let db = Firestore.firestore()
        db.collection("tournaments").document(tournamentID)
          .collection("brackets").document(bracketId)
          .collection("matches").document(matchId)
          .updateData(["winner": winner]) { [weak self] error in
              if let error = error, let self = self {
                  self.errorMessage = "Failed to update match: \(error.localizedDescription)"
                  print("❌ Error updating match winner: \(error.localizedDescription)")
              } else {
                  print("✅ Match winner updated successfully")
              }
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
    private func createMatch(team1: TeamData, team2: TeamData, winner: String = "") -> MatchData {
        return MatchData(
            team1: team1.name, 
            team2: team2.name,
            team1Players: team1.players,
            team2Players: team2.players,
            winner: winner,
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
            winner: "",
            uniqueId: UUID().uuidString
        )
    }
}
