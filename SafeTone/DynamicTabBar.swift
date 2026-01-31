//
//  DynamicTabBar.swift
//  SafeTone
//
//  Tab bar that shrinks when scrolling and expands when a tab is tapped.
//

import SwiftUI

enum MainTab: Int, CaseIterable {
    case recents = 0
    case contacts = 1
    case keypad = 2
    case shield = 3

    var title: String {
        switch self {
        case .recents: return "Recents"
        case .contacts: return "Contacts"
        case .keypad: return "Keypad"
        case .shield: return "Shield"
        }
    }

    var icon: String {
        switch self {
        case .recents: return "clock.arrow.circle"
        case .contacts: return "person.2.fill"
        case .keypad: return "circle.grid.3x3.fill"
        case .shield: return "shield.fill"
        }
    }
}

struct DynamicTabBar: View {
    @Binding var selectedTab: MainTab
    var expanded: Bool
    var onTap: (MainTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, expanded ? 12 : 8)
        .frame(height: expanded ? 72 : 56)
        .background(
            RoundedRectangle(cornerRadius: expanded ? 28 : 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: expanded ? 28 : 24)
                        .stroke(Color.safeToneGlassHighlight.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            onTap(tab)
        } label: {
            VStack(spacing: expanded ? 6 : 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: expanded ? 24 : 22, weight: .medium))
                    .foregroundStyle(isSelected ? Color.safeToneEmerald : Color.safeToneTextSecondary)
                if expanded {
                    Text(tab.title)
                        .font(SafeToneFonts.tabLabel)
                        .foregroundStyle(isSelected ? Color.safeToneTextPrimary : Color.safeToneTextSecondary)
                }
            }
            .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
