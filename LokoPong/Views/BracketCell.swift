//
//  BracketCell.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/22/25.
//

/**
 * BracketCell
 *
 * A view component that represents a single match cell in the tournament bracket.
 * This cell displays match information including team names, scores, and connecting lines
 * to visualize the tournament progression.
 *
 * Features:
 * - Displays team names and scores
 * - Shows match details in expanded mode
 * - Handles bracket connection lines based on position
 * - Supports dynamic sizing based on tournament round
 */

import SwiftUICore
import SwiftUI

struct BracketCell: View {
    // Match data containing team names and scores
    let matchData: MatchData
    
    // Configuration properties
    let heightScalingExponent: Int    // Determines cell height based on tournament round
    let isTopMatch: Bool              // Whether this is the top match in a pair
    let isCollapsed: Bool             // Controls expanded/collapsed state
    let isFirstColumn: Bool           // True if this is in the first round
    let isLastColumn: Bool            // True if this is in the final round
    
    // Default line color for bracket connections
    private var lineColor: Color {
            .black
        }
        
    // Main view composition
    var body: some View {
            HStack(spacing: 0) {
                leftLineArea            // Left connecting line
                
                VStack(spacing: 0) {
                    if !isCollapsed {
                        topLabelArea    // Match title area
                    }
                    
                    team1ScoreArea      // First team score display
                    team2ScoreArea      // Second team score display
                    
                    if !isCollapsed {
                        touchForMoreInfoArea  // Interaction hint
                    }
                }
                
                rightLineArea           // Right connecting line
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            
            // Dynamic height scaling based on tournament round
            .frame(height: height)
            .transition(.opacity.combined(with: .scale(scale: 1, anchor: .top)))
        }
    
    // Calculate cell height based on tournament round
    private var height: CGFloat {
            100 * pow(2, CGFloat(heightScalingExponent))
        }
    
    // Left connection line view
    private var leftLineArea: some View {
        Group {
            if !isFirstColumn {
                Rectangle()
                    .foregroundColor(lineColor)
                } else {
                    Spacer()
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.05, height: 2)
        }
    
    // Right connection line container
        private var rightLineArea: some View {
            Group {
                if !isLastColumn {
                    rightLine
                } else {
                    Spacer()
                        .frame(width: UIScreen.main.bounds.width * 0.05, height: 2)
                }
            }
        }
    
    // Complex right line composition
    private var rightLine: some View {
            HStack(spacing: 0) {
                rightHorizontalLine
                
                // Determine vertical line position based on match position
                if isTopMatch {
                    topMatchRightVerticalLine
                    
                } else {
                    bottomMatchRightVerticalLine
                }
            }
        }
    
    // Horizontal connecting line
    private var rightHorizontalLine: some View {
            Rectangle()
                .frame(width: UIScreen.main.bounds.width * 0.05, height: 2)
                .foregroundColor(lineColor)
        }
    
    // Vertical line for top matches
    private var topMatchRightVerticalLine: some View {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: height / 2)
                Rectangle()
                    .frame(width: 2, height: height / 2 + 2)
                    .foregroundColor(lineColor)
            }
        }
    
    // Vertical line for bottom matches
    private var bottomMatchRightVerticalLine: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .frame(width: 2, height: height / 2 + 2)
                    .foregroundColor(lineColor)
                Spacer()
                    .frame(height: height / 2)
            }
        }
    
    // Match title display area
    private var topLabelArea: some View {
        Text("\(matchData.team1) - \(matchData.team2)")
            .foregroundColor(.white)
            .bold()
            .frame(height: 20)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.gray)
    }
    
    // First team score display
    private var team1ScoreArea: some View {
        HStack(spacing: 0) {
            Text(matchData.team1)
            Spacer()
            Text("\(matchData.team1Score)")
                .bold()
        }
        .padding(.horizontal)
        .frame(height: 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .border(Color.black, width: 1)
    }
    
    // Second team score display
    private var team2ScoreArea: some View {
        HStack(spacing: 0) {
            Text(matchData.team2)
            Spacer()
            Text("\(matchData.team2Score)")
                .bold()
        }
        .padding(.horizontal)
        .frame(height: 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .border(Color.black, width: 1)
    }
    
    // Interactive hint area
    private var touchForMoreInfoArea: some View {
        Text("Touch For More Info")
            .frame(height: 20)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .foregroundColor(.black)
    }
    
}

// Preview provider for SwiftUI canvas
struct BracketCell_Previews: PreviewProvider {
    private static let previewMatchData = MatchData(team1: "Team 1", team2: "Team 2", team1Score: 2, team2Score: 1)
    
    static var previews: some View {
        BracketCell(matchData: previewMatchData,
                              heightScalingExponent: 0,
                              isTopMatch: true,
                              isCollapsed: false,
                              isFirstColumn: true,
                              isLastColumn: false)
    }
}
