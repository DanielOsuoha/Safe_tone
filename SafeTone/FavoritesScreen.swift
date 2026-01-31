//
//  FavoritesScreen.swift
//  SafeTone
//
//  Native Phone-style Favorites list. Black background, 17pt body.
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
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Favorites")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(mockFavorites) { item in
                            Button {
                                // Mock tap
                            } label: {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(Color(UIColor.systemGray4))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(item.name.prefix(1)))
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(.white)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundStyle(.white)
                                        Text(item.subtitle)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundStyle(Color(UIColor.systemGray))
                                    }
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.green)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .frame(minHeight: 60)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

#Preview {
    FavoritesScreen()
}
