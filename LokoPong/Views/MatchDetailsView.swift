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
            teamNamesArea     // Team names display
            teamScoresArea    // Score display
        }
    }
    
    // Team names display with VS separator
    private var teamNamesArea: some View {
        HStack(spacing: 40) {
            // First team name with dynamic opacity based on score
            Text(matchData.team1.uppercased())
                .bold()
                .opacity(matchData.team1Score > matchData.team2Score ? 1 : 0.3)
            
            // VS separator
            Text("vs")
                .font(.system(size: 16))
            
            // Second team name with dynamic opacity based on score
            Text(matchData.team2.uppercased())
                .bold()
                .opacity(matchData.team2Score > matchData.team1Score ? 1 : 0.3)
        }
        .font(.system(size: 32))
    }
    
    // Score display with separator
    private var teamScoresArea: some View {
        HStack(spacing: 20) {
            // First team score with dynamic opacity
            Text("\(matchData.team1Score)".uppercased())
                .bold()
                .opacity(matchData.team1Score > matchData.team2Score ? 1 : 0.3)
            
            // Score separator
            Text(":")
                .font(.system(size: 16))
            
            // Second team score with dynamic opacity
            Text("\(matchData.team2Score)".uppercased())
                .bold()
                .opacity(matchData.team2Score > matchData.team1Score ? 1 : 0.3)
        }
        .font(.system(size: 48))
    }
}

// Preview provider for SwiftUI canvas
struct MatchDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchDetailsView(matchData: .init(team1: "Team 1", team2: "Team 2", team1Score: 3, team2Score: 0))
    }
}
