//
//  SafeToneApp.swift
//  SafeTone
//
//  Created by Daniel Osuoha on 1/30/26.
//

import SwiftUI

@main
struct SafeToneApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var callManager = CallManager.shared
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(callManager)
            } else {
                WelcomeView()
                    .environmentObject(callManager)
            }
        }
    }
}
