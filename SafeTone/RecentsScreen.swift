//
//  RecentsScreen.swift
//  SafeTone
//
//  Native iPhone Recents: standard List, blue info.circle on the right, missed calls in Red.
//

import SwiftUI

struct RecentItem: Identifiable {
    let id = UUID()
    let name: String
    let callType: String
    let timestamp: String
    let isMissed: Bool
}

private let mockRecents: [RecentItem] = [
    RecentItem(name: "+1 (555) 123-4567", callType: "iPhone", timestamp: "Today, 2:34 PM", isMissed: false),
    RecentItem(name: "Alice Chen", callType: "mobile", timestamp: "Yesterday", isMissed: false),
    RecentItem(name: "Unknown", callType: "mobile", timestamp: "Yesterday", isMissed: true),
    RecentItem(name: "+1 (555) 987-6543", callType: "iPhone", timestamp: "Mon", isMissed: true),
]

struct RecentsScreen: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Recents")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                List {
                    ForEach(mockRecents) { item in
                        recentRow(item)
                            .listRowBackground(Color.black)
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
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Text(item.timestamp)
                    .font(SafeToneFonts.body)
                    .foregroundStyle(Color(UIColor.systemGray))
                    .frame(width: 80, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(item.isMissed ? Color.red : .white)
                    Text(item.callType)
                        .font(SafeToneFonts.body)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
                Spacer()
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.blue)
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
