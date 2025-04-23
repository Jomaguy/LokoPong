//
//  BracketColumnView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/22/25.
//

/**
 * BracketColumnView
 *
 * A view component that represents a single column in the tournament bracket.
 * Each column contains multiple BracketCell views arranged vertically, representing
 * the matches for a specific round of the tournament.
 *
 * Features:
 * - Displays a vertical stack of match cells
 * - Handles column-specific scaling and layout
 * - Supports focused/unfocused states
 * - Manages match cell interaction
 */

import SwiftUICore
import SwiftUI

struct BracketColumnView: View {
    // Column configuration properties
    let bracket: Bracket              // Data for all matches in this round
    let columnIndex: Int             // Position of this column in the bracket
    let focusedColumnIndex: Int      // Currently focused column index
    let lastColumnIndex: Int         // Index of the final column
    let didTapCell: (MatchData) -> Void  // Callback for cell selection
    
    var body: some View {
            LazyVStack(spacing: 0) {
                // Create cells for each match in the bracket
                ForEach(0 ..< bracket.matches.count, id: \.self) { matchIndex in
                    BracketCell(matchData: bracket.matches[matchIndex],
                                          heightScalingExponent: columnIndex - focusedColumnIndex,
                                          isTopMatch: matchIndex % 2 == 0,  // Alternates between top/bottom matches
                                          isCollapsed: columnIndex < focusedColumnIndex,  // Collapse columns before focused column
                                          isFirstColumn: columnIndex == 0,
                                          isLastColumn: columnIndex == lastColumnIndex)
                    
                    // Handle cell tap interaction
                    .onTapGesture {
                        didTapCell(bracket.matches[matchIndex])
                    }
                }
            }
        }
    }

// Preview provider for SwiftUI canvas
struct BracketColumnView_Previews: PreviewProvider {
    // Sample data for preview
    private static let previewBracket: Bracket = Bracket(name: "Semi Finals",
                                                         matches: [
                                                            .init(team1: "Team 1", team2: "Team 2",
                                                                  team1Players: ["Player 1A", "Player 1B"],
                                                                  team2Players: ["Player 2A", "Player 2B"]),
                                                            .init(team1: "Team 3", team2: "Team 4",
                                                                  team1Players: ["Player 3A", "Player 3B"],
                                                                  team2Players: ["Player 4A", "Player 4B"]),
                                                            .init(team1: "Team 5", team2: "Team 6",
                                                                  team1Players: ["Player 5A", "Player 5B"],
                                                                  team2Players: ["Player 6A", "Player 6B"]),
                                                            .init(team1: "Team 7", team2: "Team 8",
                                                                  team1Players: ["Player 7A", "Player 7B"],
                                                                  team2Players: ["Player 8A", "Player 8B"]),
                                                        ])
    
    static var previews: some View {
            BracketColumnView(bracket: previewBracket,
                                        columnIndex: 0,
                                        focusedColumnIndex: 0,
                                        lastColumnIndex: 2,
                                        didTapCell: { _ in })
                .padding(.horizontal)
        }
    }
