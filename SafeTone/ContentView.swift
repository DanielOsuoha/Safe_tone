//  Standard SwiftUI TabView — native iPhone Phone app layout. Tab bar never disappears.

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 2 
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

                DialerScreen()
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
            
            // Full-screen overlay when call is answered
            if callKitManager.isCallAnswered {
                InCallScreen(
                    callerName: "Alice Chen",
                    verificationStatus: callKitManager.verificationStatus,
                    onEndCall: {
                        callKitManager.isCallAnswered = false
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: callKitManager.isCallAnswered)
    }
}

#Preview {
    ContentView()
}
