//
//  ContentView.swift
//  SafeTone
//
//  Standard SwiftUI TabView — native iPhone Phone app layout. Tab bar never disappears.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 3 // Keypad
    @State private var showLiveCall: Bool = false
    @StateObject private var callKitManager = CallKitManager.shared

    var body: some View {
        ZStack {
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
            .tint(Color.blue)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showLiveCall) {
                LiveCallMockup()
            }
            
            // In-Call Screen Overlay
            if callKitManager.isCallAnswered {
                InCallScreen(
                    callerName: callKitManager.currentCallerName,
                    verificationStatus: callKitManager.verificationStatus,
                    onEndCall: {
                        // End the call via CallKit
                        // Note: In production, you'd need to track the UUID
                        callKitManager.isCallAnswered = false
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: callKitManager.isCallAnswered)
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
