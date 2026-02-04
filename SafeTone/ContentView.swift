//  Standard SwiftUI TabView — native iPhone Phone app layout. Tab bar never disappears.

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 2 
    @State private var showLiveCall: Bool = false
    @StateObject private var callKitManager = CallKitManager.shared

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                RecentsScreen()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("Recents")
                    }
                    .tag(0)

                ContactsScreen()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Contacts")
                    }
                    .tag(1)

                DialerTabView(onCallTapped: { showLiveCall = true })
                    .tabItem {
                        Image(systemName: "circle.grid.3x3.fill")
                        Text("Keypad")
                    }
                    .tag(2)

                ShieldSettings()
                    .tabItem {
                        Image(systemName: "shield.fill")
                        Text("Shield")
                    }
                    .tag(3)
            }
            .tint(Color.blue)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showLiveCall) {
                InCallScreen(
                    callerName: "Unknown Caller",
                    verificationStatus: .analyzing,
                    onEndCall: {
                        showLiveCall = false
                    }
                )
            }
            
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
