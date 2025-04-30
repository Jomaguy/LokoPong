import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

/**
 * AdminMatchUpdateViewModel
 *
 * Extends tournament visualization with admin functionality for updating match results.
 * - Handles match selection
 * - Updates match results
 * - Propagates winners to next rounds
 * - Persists changes to the database
 */
class AdminMatchUpdateViewModel: ObservableObject {
    // Reuse the tournament draw view model for bracket visualization
    @Published var tournamentViewModel = TournamentDrawViewModel()
    
    // Admin-specific state
    @Published var selectedMatch: MatchData? = nil
    @Published var isProcessingUpdate: Bool = false
    @Published var errorMessage: String? = nil
    
    // Keep track of brackets for direct manipulation
    private var allBrackets: [Bracket] = []
    
    // Lazy initialize Firestore to prevent initialization issues
    private lazy var db = Firestore.firestore()
    
    // Cancel bag for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Helper method to get the current tournament ID
    private func getCurrentTournamentID() -> String? {
        return tournamentViewModel.currentTournamentID ?? UserDefaults.standard.string(forKey: "currentTournamentID")
    }
    
    init() {
        // Subscribe to bracket changes in the tournament view model
        tournamentViewModel.$brackets
            .sink { [weak self] (brackets: [Bracket]) in
                self?.allBrackets = brackets
            }
            .store(in: &cancellables)
    }
    
    // Load tournament data
    func loadTournamentData() {
        // Store the current match ID before reloading
        let selectedMatchId = selectedMatch?.id
        
        // Load tournament data
        tournamentViewModel.loadTournamentFromFirestore()
        
        // If we had a selected match, try to reselect it after loading completes
        if let matchId = selectedMatchId {
            // Use the brackets publisher to know when data is loaded
            tournamentViewModel.$brackets
                .dropFirst() // Skip the initial empty value
                .first() // Take only the first emission after loading
                .sink { [weak self] _ in
                    // Reselect the match by ID
                    self?.selectMatch(withId: matchId)
                }
                .store(in: &cancellables)
        }
    }
    
    // Load tournament data from Firestore
    func loadTournamentFromFirestore() {
        // Store the current match ID before reloading
        let selectedMatchId = selectedMatch?.id
        
        // Load tournament data from Firestore
        tournamentViewModel.loadTournamentFromFirestore()
        
        // If we had a selected match, try to reselect it after loading completes
        if let matchId = selectedMatchId {
            // Use the brackets publisher to know when data is loaded
            tournamentViewModel.$brackets
                .dropFirst() // Skip the initial empty value
                .first() // Take only the first emission after loading
                .sink { [weak self] _ in
                    // Reselect the match by ID
                    self?.selectMatch(withId: matchId)
                }
                .store(in: &cancellables)
        }
    }
    
    // Find and select a match by its ID
    func selectMatch(withId id: String) {
        // Search through all brackets to find the match
        for bracket in tournamentViewModel.brackets {
            if let match = bracket.matches.first(where: { $0.id == id }) {
                self.selectedMatch = match
                return
            }
        }
    }
    
    // Update match result with the selected winner
    func updateMatchResult(_ updatedMatch: MatchData, winner: String) {
        guard let selectedMatch = selectedMatch else { return }
        
        isProcessingUpdate = true
        errorMessage = nil
        
        // Find the current match's position in the brackets
        var currentBracketIndex = -1
        var currentMatchIndex = -1
        
        // Find which bracket and position this match is in
        for (bracketIndex, bracket) in allBrackets.enumerated() {
            if let matchIndex = bracket.matches.firstIndex(where: { $0.id == selectedMatch.id }) {
                currentBracketIndex = bracketIndex
                currentMatchIndex = matchIndex
                break
            }
        }
        
        // If we couldn't find the match, return with an error
        if currentBracketIndex == -1 || currentMatchIndex == -1 {
            isProcessingUpdate = false
            errorMessage = "Could not find the selected match in the tournament"
            return
        }
        
        // Create a mutable copy of the match with the updated winner
        var updatedMatchData = selectedMatch
        updatedMatchData.winner = winner
        
        // Update the local selectedMatch to immediately reflect the change in the UI
        self.selectedMatch = updatedMatchData
        
        // Get the current tournament ID from UserDefaults
        guard let tournamentID = getCurrentTournamentID() else {
            isProcessingUpdate = false
            errorMessage = "No active tournament found"
            return
        }
        
        // Update the match in Firestore
        // Reference format: tournaments/{tournamentID}/brackets/bracketId/matches/matchId
        let matchRef = db.collection("tournaments").document(tournamentID)
            .collection("brackets").document(allBrackets[currentBracketIndex].id)
            .collection("matches").document(selectedMatch.id)
        
        matchRef.updateData([
            "winner": winner
        ]) { [weak self] (error: Error?) in
            guard let self = self else { return }
            
            if let error = error {
                self.isProcessingUpdate = false
                self.errorMessage = "Failed to update match: \(error.localizedDescription)"
                return
            }
            
            // Now update the next round with the winner
            self.updateNextRoundWithWinner(
                match: updatedMatchData,
                winner: winner,
                roundIndex: currentBracketIndex,
                matchIndex: currentMatchIndex
            )
        }
    }
    
    // Helper method to determine winner and update next round
    private func updateNextRoundWithWinner(match: MatchData, winner: String, roundIndex: Int, matchIndex: Int) {
        // Update the local tournament view model immediately for responsive UI
        updateLocalBracketData(match: match, winner: winner, roundIndex: roundIndex, matchIndex: matchIndex)
        
        // Get the current tournament ID from UserDefaults
        guard let tournamentID = getCurrentTournamentID() else {
            isProcessingUpdate = false
            errorMessage = "No active tournament found"
            return
        }
        
        // If this isn't the final round, update the next round
        if roundIndex < allBrackets.count - 1 {
            // Calculate the index in the next round
            let nextRoundMatchIndex = matchIndex / 2
            
            // If we're the first match of the pair, update team1
            // If we're the second match of the pair, update team2
            let isFirstMatchOfPair = matchIndex % 2 == 0
            
            // Find the winner's players
            let winnerPlayers = match.team1 == winner ? match.team1Players : match.team2Players
            
            // Get the next round's bracket
            let nextRoundBracket = allBrackets[roundIndex + 1]
            
            // Make sure the next round has enough matches
            if nextRoundMatchIndex < nextRoundBracket.matches.count {
                let nextRoundMatchId = nextRoundBracket.matches[nextRoundMatchIndex].id
                
                // Update the next round match with the winner
                // Reference format: tournaments/{tournamentID}/brackets/bracketId/matches/matchId
                let nextRoundMatchRef = db.collection("tournaments").document(tournamentID)
                    .collection("brackets").document(nextRoundBracket.id)
                    .collection("matches").document(nextRoundMatchId)
                
                // Determine which field to update based on whether this is the first or second match
                let fieldToUpdate = isFirstMatchOfPair ? "team1" : "team2"
                let playerFieldToUpdate = isFirstMatchOfPair ? "team1Players" : "team2Players"
                
                nextRoundMatchRef.updateData([
                    fieldToUpdate: winner,
                    playerFieldToUpdate: winnerPlayers
                ]) { [weak self] (error: Error?) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.isProcessingUpdate = false
                        self.errorMessage = "Failed to update next round: \(error.localizedDescription)"
                        print("Error updating next round: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Successfully updated next round with winner: \(winner)")
                    
                    // All updates completed successfully
                    self.isProcessingUpdate = false
                    
                    // Reload tournament data to reflect changes
                    self.loadTournamentFromFirestore()
                }
            } else {
                // This shouldn't happen in a properly structured tournament
                print("Error: Next round match not found at index \(nextRoundMatchIndex)")
                isProcessingUpdate = false
                errorMessage = "Next round match not found"
            }
        } else {
            // This is the final round, no next match to update
            print("Final round match updated with winner: \(winner)")
            isProcessingUpdate = false
            
            // Reload tournament data to reflect changes
            self.loadTournamentFromFirestore()
        }
    }
    
    // Update local bracket data immediately for responsive UI
    private func updateLocalBracketData(match: MatchData, winner: String, roundIndex: Int, matchIndex: Int) {
        // Safety check for index bounds
        guard roundIndex >= 0 && roundIndex < tournamentViewModel.brackets.count,
              matchIndex >= 0 && matchIndex < tournamentViewModel.brackets[roundIndex].matches.count else {
            return
        }
        
        // Create mutable copies of the brackets for updating
        var updatedBrackets = tournamentViewModel.brackets
        
        // Create a mutable copy of the bracket
        let bracketId = updatedBrackets[roundIndex].id
        let bracketName = updatedBrackets[roundIndex].name
        var updatedMatches = updatedBrackets[roundIndex].matches
        
        // Update the match with the new winner
        updatedMatches[matchIndex] = match
        
        // Create a new bracket with the updated matches
        updatedBrackets[roundIndex] = Bracket(id: bracketId, name: bracketName, matches: updatedMatches)
        
        // If this isn't the final round, also update the next round match
        if roundIndex < updatedBrackets.count - 1 {
            let nextRoundMatchIndex = matchIndex / 2
            
            // Safety check for index bounds in next round
            if nextRoundMatchIndex < updatedBrackets[roundIndex + 1].matches.count {
                // Check if first or second match of the pair
                let isFirstMatchOfPair = matchIndex % 2 == 0
                
                // Get the existing match from the next round
                var nextRoundMatch = updatedBrackets[roundIndex + 1].matches[nextRoundMatchIndex]
                
                // Find the winner's players
                let winnerPlayers = match.team1 == winner ? match.team1Players : match.team2Players
                
                // Update the appropriate team in the next round match
                if isFirstMatchOfPair {
                    nextRoundMatch = MatchData(
                        team1: winner,
                        team2: nextRoundMatch.team2,
                        team1Players: winnerPlayers,
                        team2Players: nextRoundMatch.team2Players,
                        winner: nextRoundMatch.winner,
                        uniqueId: nextRoundMatch.uniqueId
                    )
                } else {
                    nextRoundMatch = MatchData(
                        team1: nextRoundMatch.team1,
                        team2: winner,
                        team1Players: nextRoundMatch.team1Players,
                        team2Players: winnerPlayers,
                        winner: nextRoundMatch.winner,
                        uniqueId: nextRoundMatch.uniqueId
                    )
                }
                
                // Create a mutable copy of the next round bracket's matches
                let nextRoundBracketId = updatedBrackets[roundIndex + 1].id
                let nextRoundBracketName = updatedBrackets[roundIndex + 1].name
                var nextRoundMatches = updatedBrackets[roundIndex + 1].matches
                
                // Update the next round match
                nextRoundMatches[nextRoundMatchIndex] = nextRoundMatch
                
                // Create a new bracket with the updated matches
                updatedBrackets[roundIndex + 1] = Bracket(
                    id: nextRoundBracketId,
                    name: nextRoundBracketName,
                    matches: nextRoundMatches
                )
            }
        }
        
        // Update the published brackets on the main thread
        DispatchQueue.main.async {
            self.tournamentViewModel.brackets = updatedBrackets
            self.allBrackets = updatedBrackets
        }
    }
} 