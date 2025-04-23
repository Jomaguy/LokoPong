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
                
                TournamentDrawView(brackets: sampleBrackets)
                    .tabItem {
                        Label("Draw", systemImage: "trophy")
                    }
            }
            .environmentObject(tournamentManager)
        }
    }
}
