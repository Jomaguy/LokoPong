//
//  BracketColumnView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/22/25.
//

import SwiftUI
import FirebaseFirestore

/**
 * BracketColumnView
 *
 * A view component that represents a single column in the tournament bracket.
 * Each column contains match views arranged vertically, representing
 * the matches for a specific round of the tournament.
 *
 * Features:
 * - Displays a vertical stack of match cells
 * - Handles column-specific scaling and layout
 * - Supports focused/unfocused states
 * - Displays TBD matches with appropriate styling for pending matches
 */

struct BracketColumnView: View {
    // Column configuration properties
    let bracket: Bracket              // Data for all matches in this round
    let columnIndex: Int             // Position of this column in the bracket
    let focusedColumnIndex: Int      // Currently focused column index
    let lastColumnIndex: Int         // Index of the final column
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(bracket.name)
                .font(.headline)
                .padding(.bottom, 10)
                .opacity(columnIndex == focusedColumnIndex ? 1.0 : 0.6)
            
            ForEach(bracket.matches) { match in
                MatchView(match: match, 
                          isFirstRound: columnIndex == 0, 
                          isTBD: match.team1 == "TBD" || match.team2 == "TBD")
                    .padding(.vertical, 5)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .opacity(columnIndex == focusedColumnIndex ? 1.0 : 0.5)
        )
        .scaleEffect(columnIndex == focusedColumnIndex ? 1.0 : 0.9)
    }
}

// Preview provider for SwiftUI canvas
struct BracketColumnView_Previews: PreviewProvider {
    // Sample data for preview
    private static let previewBracket: Bracket = Bracket(
        name: "Semi Finals",
        matches: [
            MatchData(
                team1: "Team 1", 
                team2: "Team 2",
                team1Players: ["Player 1A", "Player 1B"],
                team2Players: ["Player 2A", "Player 2B"],
                uniqueId: "preview1"
            ),
            MatchData(
                team1: "TBD", 
                team2: "TBD",
                team1Players: [],
                team2Players: [],
                uniqueId: "preview2"
            )
        ]
    )
    
    static var previews: some View {
        BracketColumnView(
            bracket: previewBracket,
            columnIndex: 0,
            focusedColumnIndex: 0,
            lastColumnIndex: 2
        )
        .padding(.horizontal)
    }
}
