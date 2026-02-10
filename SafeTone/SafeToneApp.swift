//
//  SafeToneApp.swift
//  SafeTone
//
//  Created by Daniel Osuoha on 1/30/26.
//

import SwiftUI

@main
struct SafeToneApp: App {
    @State private var showWelcome = true
    
    var body: some Scene {
        WindowGroup {
            if showWelcome {
                WelcomeView(showWelcome: $showWelcome)
            } else {
                ContentView()
            }
        }
    }
}
