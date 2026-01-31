//
//  ContentView.swift
//  SafeTone
//
//  Root: dynamic tab bar (Recents, Contacts, Keypad, Shield) and tab content.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MainTab = .recents
    @State private var tabBarExpanded: Bool = true
    @State private var scrollOffset: CGFloat = 0
    @State private var showLiveCall: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.safeToneNavy.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .recents:
                    RecentsScreen(onScrollOffset: { scrollOffset = $0 })
                case .contacts:
                    ContactsScreen(onScrollOffset: { scrollOffset = $0 })
                case .keypad:
                    DialerScreenWrapper(onCallTapped: { showLiveCall = true })
                case .shield:
                    ShieldSettings(onScrollOffset: { scrollOffset = $0 })
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            DynamicTabBar(selectedTab: $selectedTab, expanded: tabBarExpanded) { tab in
                selectedTab = tab
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    tabBarExpanded = true
                }
            }
        }
        .onChange(of: scrollOffset) { _, newValue in
            withAnimation(.easeOut(duration: 0.25)) {
                tabBarExpanded = newValue > 10
            }
        }
        .sheet(isPresented: $showLiveCall) {
            LiveCallMockup()
        }
    }
}

struct DialerScreenWrapper: View {
    var onCallTapped: () -> Void

    var body: some View {
        DialerScreen(onCallTapped: onCallTapped)
    }
}

#Preview {
    ContentView()
}
