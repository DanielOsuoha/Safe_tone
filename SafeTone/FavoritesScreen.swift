//
//  FavoritesScreen.swift
//  SafeTone
//
//  Native iOS 26 Phone layout. Solid Deep Blue, Pure White, 60pt touch targets.
//

import SwiftUI

struct FavoriteItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
}

private let mockFavorites: [FavoriteItem] = [
    FavoriteItem(name: "Alice Chen", subtitle: "mobile"),
    FavoriteItem(name: "Bob Martinez", subtitle: "home"),
    FavoriteItem(name: "Carol Williams", subtitle: "mobile"),
]

struct FavoritesScreen: View {
    var body: some View {
        ZStack {
            Color.safeToneDeepBlue.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Favorites")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.safeTonePureWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                List {
                    ForEach(mockFavorites) { item in
                        Button {
                            // Mock tap
                        } label: {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.safeTonePureWhite.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(item.name.prefix(1)))
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color.safeTonePureWhite)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(Color.safeTonePureWhite)
                                    Text(item.subtitle)
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
                        .listRowBackground(Color.safeToneDeepBlue)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    FavoritesScreen()
}
