//
//  ContentView.swift
//  SafeTone
//
//  Native-style tab bar: Favorites, Recents, Contacts, Keypad, Voicemail.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 3 // Keypad
    @State private var showLiveCall: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FavoritesScreen()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
                .tag(0)

            RecentsScreen()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Recents")
                }
                .tag(1)

            ContactsScreen()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Contacts")
                }
                .tag(2)

            DialerTabView(onCallTapped: { showLiveCall = true })
                .tabItem {
                    Image(systemName: "circle.grid.3x3.fill")
                    Text("Keypad")
                }
                .tag(3)

            VoicemailScreen()
                .tabItem {
                    Image(systemName: "recordingtape")
                    Text("Voicemail")
                }
                .tag(4)
        }
        .tint(Color(hex: "0A84FF"))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLiveCall) {
            LiveCallMockup()
        }
    }
}

struct DialerTabView: View {
    var onCallTapped: () -> Void

    var body: some View {
        DialerScreen(onCallTapped: onCallTapped)
    }
}

#Preview {
    ContentView()
}
