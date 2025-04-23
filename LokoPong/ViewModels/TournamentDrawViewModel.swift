import Foundation
import FirebaseFirestore

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
    let team1Score: Int
    let team2Score: Int
    
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
    // Published property to trigger UI updates when teams change
    @Published var brackets: [Bracket] = []
    @Published var teams: [Team] = []
    // Firebase database reference
    private let db = Firestore.firestore()
    
}
