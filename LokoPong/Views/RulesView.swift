//
//  RulesView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

import SwiftUI

/**
 * RulesView
 *
 * A view that displays the official tournament rules.
 * Shows a scrollable list of rules with sections.
 */
struct RulesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Game Setup Section
                    RuleSection(title: "Game Setup", rules: [
                        "Teams consist of 2 players each",
                        "10 cups per team arranged in a triangle",
                        "Cups are filled according to tournament standards",
                        "Teams stand behind their respective tables"
                    ])
                    
                    // Gameplay Section
                    RuleSection(title: "Gameplay", rules: [
                        "Teams alternate turns throwing ping pong balls",
                        "Each player throws one ball per turn",
                        "If both players hit cups in the same turn, those cups are removed and the team shoots again",
                        "Balls can be thrown directly or bounced",
                        "Defending team can block bounced shots"
                    ])
                    
                    // Scoring Section
                    RuleSection(title: "Scoring & Winning", rules: [
                        "When a ball lands in a cup, that cup is removed",
                        "Game ends when one team eliminates all opponent's cups",
                        "If both teams make their last cup in the same round, overtime rules apply",
                        "In overtime, each team gets 3 cups in a triangle formation"
                    ])
                    
                    // Special Rules
                    RuleSection(title: "Special Rules", rules: [
                        "Balls that bounce back can be retrieved for re-throws",
                        "Knocking over cups results in those cups being removed",
                        "Interference with ball trajectory results in penalty cup",
                        "Teams can request rack rearrangement once per game"
                    ])
                }
                .padding()
            }
            .navigationTitle("Official Rules")
        }
    }
}

// Helper view for rule sections
struct RuleSection: View {
    let title: String
    let rules: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(rules, id: \.self) { rule in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.blue)
                    Text(rule)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    RulesView()
} 