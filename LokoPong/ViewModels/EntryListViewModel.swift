//
//  EntryListViewModel.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

import Foundation
import FirebaseFirestore

/**
 * EntryListViewModel
 *
 * Manages the data for the tournament entry list.
 * Handles loading and updating team data from Firestore.
 */
@MainActor
class EntryListViewModel: ObservableObject {
    @Published var teams: [TeamData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let teamService = TeamService()
    
    func loadTeams() async {
        isLoading = true
        error = nil
        
        do {
            teams = try await teamService.fetchTeamsAsync()
            isLoading = false
        } catch {
            self.error = "Failed to load teams: \(error.localizedDescription)"
            isLoading = false
        }
    }
} 