//
//  RecentsScreen.swift
//  SafeTone
//
//  Mock recents list — high contrast, large touch targets.
//

import SwiftUI

struct RecentItem: Identifiable {
    let id = UUID()
    let label: String
    let detail: String
    let isVerified: Bool
}

private let mockRecents: [RecentItem] = [
    RecentItem(label: "+1 (555) 123-4567", detail: "Today, 2:34 PM", isVerified: true),
    RecentItem(label: "Alice Chen", detail: "Yesterday", isVerified: true),
    RecentItem(label: "Unknown", detail: "Yesterday", isVerified: false),
    RecentItem(label: "+1 (555) 987-6543", detail: "Mon", isVerified: false),
]

struct RecentsScreen: View {
    var onScrollOffset: ((CGFloat) -> Void)?

    var body: some View {
        ZStack {
            Color.safeToneNavy.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Recents")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(Color.safeToneTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mockRecents) { item in
                            recentRow(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        onScrollOffset?(value)
                    }
                }
                .coordinateSpace(name: "scroll")
            }
        }
    }

    private func recentRow(_ item: RecentItem) -> some View {
        Button {
            // Mock tap
        } label: {
            HStack(spacing: 16) {
                Image(systemName: item.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(item.isVerified ? Color.safeToneVerifiedGreen : Color.safeToneScamRed)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(SafeToneFonts.bodyBold)
                        .foregroundStyle(Color.safeToneTextPrimary)
                    Text(item.detail)
                        .font(SafeToneFonts.body)
                        .foregroundStyle(Color.safeToneTextSecondary)
                }
                Spacer()
                Image(systemName: "phone.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.safeToneEmerald)
                    .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                    .contentShape(Rectangle())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(minHeight: kMinTouchTarget)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.safeToneGlassWhite.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.safeToneGlassHighlight.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecentsScreen()
}
