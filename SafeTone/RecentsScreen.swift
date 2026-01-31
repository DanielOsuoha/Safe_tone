//
//  RecentsScreen.swift
//  SafeTone
//
//  Native iOS 26 Phone layout: Name (Large Bold), Subtitle (Call Type), Timestamp (leading). Missed = red.
//

import SwiftUI

struct RecentItem: Identifiable {
    let id = UUID()
    let name: String
    let callType: String
    let timestamp: String
    let isMissed: Bool
    let isVerified: Bool
}

private let mockRecents: [RecentItem] = [
    RecentItem(name: "+1 (555) 123-4567", callType: "iPhone", timestamp: "Today, 2:34 PM", isMissed: false, isVerified: true),
    RecentItem(name: "Alice Chen", callType: "mobile", timestamp: "Yesterday", isMissed: false, isVerified: true),
    RecentItem(name: "Unknown", callType: "mobile", timestamp: "Yesterday", isMissed: true, isVerified: false),
    RecentItem(name: "+1 (555) 987-6543", callType: "iPhone", timestamp: "Mon", isMissed: true, isVerified: false),
]

struct RecentsScreen: View {
    var body: some View {
        ZStack {
            Color.safeToneDeepBlue.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Recents")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.safeTonePureWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                List {
                    ForEach(mockRecents) { item in
                        recentRow(item)
                            .listRowBackground(Color.safeToneDeepBlue)
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func recentRow(_ item: RecentItem) -> some View {
        Button {
            // Mock tap
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Text(item.timestamp)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.safeTonePureWhite.opacity(0.7))
                    .frame(width: 80, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(item.isMissed ? Color.red : Color.safeTonePureWhite)
                    Text(item.callType)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.safeTonePureWhite.opacity(0.8))
                }
                Spacer()
                Image(systemName: "phone.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.safeToneEmerald)
                    .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                    .contentShape(Rectangle())
            }
            .frame(minHeight: kMinTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecentsScreen()
}
