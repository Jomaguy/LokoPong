//
//  LokoPongApp.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/22/25.
//

import SwiftUI
import FirebaseCore

@main
struct LokoPongApp: App {
    @StateObject private var tournamentManager = TournamentManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                TeamRegistrationView()
                    .tabItem {
                        Label("Register", systemImage: "pencil")
                    }
                
                TournamentDrawView(viewModel: TournamentDrawViewModel())
                    .tabItem {
                        Label("Draw", systemImage: "trophy")
                    }
                
                EntryListView()
                    .tabItem {
                        Label("Entry List", systemImage: "list.bullet")
                    }
                
                RulesView()
                    .tabItem {
                        Label("Rules", systemImage: "book")
                    }
            }
            .environmentObject(tournamentManager)
            .preferredColorScheme(.light)
        }
    }
}
