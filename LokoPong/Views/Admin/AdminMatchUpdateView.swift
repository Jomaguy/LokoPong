import SwiftUI

/**
 * AdminMatchUpdateView
 *
 * Admin interface for updating tournament match results.
 * Reuses the tournament bracket structure but adds:
 * - Ability to select matches for updating
 * - Interface for entering scores and confirming winners
 * - Match result update functionality
 */
struct AdminMatchUpdateView: View {
    @StateObject private var viewModel = AdminMatchUpdateViewModel()
    @State private var selectedMatchId: String? = nil
    @State private var isEditingMatch = false
    
    var body: some View {
        VStack {
            // Header
            Text("Tournament Management")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Tap on any match to update results")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            // Reuse the TournamentDrawView but with admin functionality
            TournamentDrawView(viewModel: viewModel.tournamentViewModel, 
                              matchSelectionHandler: { matchId in
                                  self.selectedMatchId = matchId
                              })
                .environmentObject(viewModel)
                .onChange(of: selectedMatchId) { id in
                    if let id = id {
                        viewModel.selectMatch(withId: id)
                        isEditingMatch = true
                    }
                }
                .sheet(isPresented: $isEditingMatch) {
                    if let match = viewModel.selectedMatch {
                        MatchUpdateSheet(match: match, onUpdate: { updatedMatch, winner in
                            viewModel.updateMatchResult(updatedMatch, winner: winner)
                            isEditingMatch = false
                            selectedMatchId = nil
                        }, onCancel: {
                            isEditingMatch = false
                            selectedMatchId = nil
                        })
                    }
                }
        }
        .onAppear {
            viewModel.loadTournamentFromFirestore()
        }
    }
}

// Sheet for updating a match result
struct MatchUpdateSheet: View {
    let match: MatchData
    let onUpdate: (MatchData, String) -> Void
    let onCancel: () -> Void
    
    @State private var selectedWinner: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Match Details")) {
                    HStack {
                        Text("Team 1:")
                        Spacer()
                        Text(match.team1)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Team 2:")
                        Spacer()
                        Text(match.team2)
                            .fontWeight(.semibold)
                    }
                }
                
                if match.team1 != "TBD" && match.team2 != "TBD" {
                    Section(header: Text("Select Winner")) {
                        Picker("Winner", selection: $selectedWinner) {
                            Text("Select a winner").tag("")
                            Text(match.team1).tag(match.team1)
                            Text(match.team2).tag(match.team2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        Button("Confirm Winner") {
                            // Only update if a winner is selected
                            if !selectedWinner.isEmpty {
                                onUpdate(match, selectedWinner)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedWinner.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(selectedWinner.isEmpty)
                    }
                } else {
                    Section {
                        Text("Cannot update TBD matches")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitle("Select Match Winner", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                onCancel()
            })
            .onAppear {
                // Reset selection when sheet appears
                selectedWinner = ""
            }
        }
    }
}

/**
 * Preview for SwiftUI canvas
 */
struct AdminMatchUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        AdminMatchUpdateView()
    }
} 