//
//  QuickkSynkkApp.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

//
//  TEAMSApp.swift
//  TEAMS
//

import SwiftUI
import FirebaseCore

@main
struct QuickkSynkkApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
