//  Standard SwiftUI TabView — native iPhone Phone app layout. Tab bar never disappears.

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 2 
    @EnvironmentObject private var callManager: CallManager

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

            if callManager.phase == .incoming {
                incomingCallBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(998)
            }
            
            if callManager.isCallScreenVisible {
                InCallScreen()
                    .transition(.move(edge: .bottom))
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: callManager.isCallScreenVisible)
        .animation(.easeInOut(duration: 0.3), value: callManager.phase)
    }

    private var incomingCallBanner: some View {
        VStack {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Incoming Call")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(callManager.callerName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    callManager.declineCall()
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)

                Button {
                    callManager.answerCall()
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.green))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(incomingBannerBackground)
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Spacer()
        }
    }

    private var incomingBannerBackground: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(height: 1)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CallManager.shared)
}
