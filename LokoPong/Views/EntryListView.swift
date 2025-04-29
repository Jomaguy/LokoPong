//
//  EntryListView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

import SwiftUI

/**
 * EntryListView
 *
 * A view that displays the tournament entry list.
 * Shows all registered teams and their players in a scrollable list.
 */
struct EntryListView: View {
    @StateObject private var viewModel = EntryListViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("Loading entries...")
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
            } else if viewModel.teams.isEmpty {
                Text("No entries yet")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.teams) { team in
                        VStack(alignment: .leading, spacing: 8) {
                            // Team name
                            Text(team.name)
                                .font(.headline)
                            
                            // Player names
                            if !team.players.isEmpty {
                                Text(team.players.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Entry List")
                .refreshable {
                    await viewModel.loadTeams()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTeams()
            }
        }
    }
}

#Preview {
    EntryListView()
} 