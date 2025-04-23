//
//  MatchDetailsView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

/**
 * MatchDetailsView
 *
 * A view component that displays detailed information about a tournament match.
 * Shows team names and scores with visual emphasis on the winning team through opacity.
 *
 * Features:
 * - Displays team names in a VS format
 * - Shows match scores
 * - Highlights winning team with full opacity
 * - Dims losing team with reduced opacity
 */

import SwiftUICore
import SwiftUI

struct MatchDetailsView: View {
    // Match data containing team names and scores
    let matchData: MatchData
    
    var body: some View {
        VStack(spacing: 16) {
            teamNamesArea      // Team names display
            playerNamesArea    // Player names display
        }
    }
    
    // Team names display with VS separator
    private var teamNamesArea: some View {
        HStack(spacing: 40) {
            // First team name
            Text(matchData.team1.uppercased())
                .bold()
            
            // VS separator
            Text("vs")
                .font(.system(size: 16))
            
            // Second team name
            Text(matchData.team2.uppercased())
                .bold()
        }
        .font(.system(size: 32))
    }
    
    // Player names display
    private var playerNamesArea: some View {
        HStack(spacing: 20) {
            // First team players
            VStack(alignment: .leading) {
                ForEach(matchData.team1Players, id: \.self) { player in
                    Text(player)
                        .font(.system(size: 16))
                }
                if matchData.team1Players.isEmpty {
                    Text("No players")
                        .font(.system(size: 16))
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Second team players
            VStack(alignment: .trailing) {
                ForEach(matchData.team2Players, id: \.self) { player in
                    Text(player)
                        .font(.system(size: 16))
                }
                if matchData.team2Players.isEmpty {
                    Text("No players")
                        .font(.system(size: 16))
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}

// Preview provider for SwiftUI canvas
struct MatchDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchDetailsView(matchData: .init(
            team1: "Team 1", 
            team2: "Team 2", 
            team1Players: ["Player 1A", "Player 1B"],
            team2Players: ["Player 2A", "Player 2B"]
        ))
    }
}
