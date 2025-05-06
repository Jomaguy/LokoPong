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
    
    // Register app delegate for Firebase setup and notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
                
                OrderOfPlayView()
                    .tabItem {
                        Label("Schedule", systemImage: "clock")
                    }
                
                EntryListView()
                    .tabItem {
                        Label("Entry List", systemImage: "list.bullet")
                    }
                
                RulesView()
                    .tabItem {
                        Label("Rules", systemImage: "book")
                    }
                
                AdminView()
                    .tabItem {
                        Label("Admin", systemImage: "lock.shield")
                    }
            }
            .environmentObject(tournamentManager)
            .preferredColorScheme(.light)
        }
    }
}
