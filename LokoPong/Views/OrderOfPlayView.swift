import SwiftUI

/**
 * OrderOfPlayView
 *
 * Displays the order of play for the tournament.
 * Shows scheduled matches with times and courts.
 */
struct OrderOfPlayView: View {
    @StateObject private var viewModel = TournamentDrawViewModel()
    
    var body: some View {
        ScheduleView(viewModel: viewModel)
            .onAppear {
                viewModel.loadTournamentFromFirestore()
            }
    }
}

// Model for schedule data
struct ScheduleMatch: Identifiable {
    let id: String
    let time: String
    let teams: String
    let isCompleted: Bool
}

// Group matches by round
struct ScheduleRound: Identifiable {
    let id: String
    let name: String
    let matches: [ScheduleMatch]
}

struct ScheduleView: View {
    @ObservedObject var viewModel: TournamentDrawViewModel
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("Loading tournament schedule...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.brackets.isEmpty {
                Text("No tournament brackets available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(scheduleData) { round in
                        Section(header: RoundHeaderView(roundName: round.name)) {
                            ForEach(round.matches) { match in
                                MatchRowView(match: match)
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                .navigationTitle("Schedule")
            }
        }
    }
    
    // Convert tournament data to schedule format
    var scheduleData: [ScheduleRound] {
        // Create a schedule round for each tournament bracket
        return viewModel.brackets.enumerated().map { roundIndex, bracket in
            let startTime = Calendar.current.date(byAdding: .hour, value: roundIndex * 2, to: Date())!
            
            // Convert matches to schedule matches
            let scheduleMatches = bracket.matches.enumerated().map { matchIndex, matchData in
                // Calculate match time based on round and match index
                let matchTime = Calendar.current.date(
                    byAdding: .minute, 
                    value: matchIndex * 30, 
                    to: startTime
                )!
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let timeString = timeFormatter.string(from: matchTime)
                
                // Create team description
                let teamDescription: String
                if matchData.team1 == "TBD" || matchData.team2 == "TBD" {
                    teamDescription = "TBD vs TBD"
                } else {
                    teamDescription = "\(matchData.team1) vs \(matchData.team2)"
                }
                
                // A match is completed if it has a winner
                let isCompleted = !matchData.winner.isEmpty
                
                return ScheduleMatch(
                    id: matchData.id,
                    time: timeString,
                    teams: teamDescription,
                    isCompleted: isCompleted
                )
            }
            
            return ScheduleRound(
                id: bracket.id,
                name: bracket.name,
                matches: scheduleMatches
            )
        }
    }
}

// Round header with custom styling
struct RoundHeaderView: View {
    let roundName: String
    
    var body: some View {
        HStack {
            Text(roundName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Individual match row
struct MatchRowView: View {
    let match: ScheduleMatch
    
    var body: some View {
        HStack(spacing: 12) {
            // Time column
            Text(match.time)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 80, alignment: .leading)
            
            // Teams column
            Text(match.teams)
                .font(.system(size: 15))
                .lineLimit(1)
            
            Spacer()
            
            // Status indicator
            StatusIndicator(isCompleted: match.isCompleted)
        }
        .padding(.vertical, 8)
    }
}

// Visual indicator for match status
struct StatusIndicator: View {
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isCompleted ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
            
            Text(isCompleted ? "Completed" : "Upcoming")
                .font(.system(size: 12))
                .foregroundColor(isCompleted ? .green : .orange)
        }
    }
}

#Preview {
    OrderOfPlayView()
} 