//
//  FavoritesScreen.swift
//  SafeTone
//
//  Native iPhone Favorites: standard List, Pure Black background.
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
            Color.safeToneBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Favorites")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(.white)
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
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(item.name.prefix(1)))
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.white)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(SafeToneFonts.body)
                                        .foregroundStyle(.white)
                                    Text(item.subtitle)
                                        .font(SafeToneFonts.body)
                                        .foregroundStyle(Color(UIColor.systemGray))
                                }
                                Spacer()
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.green)
                                    .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                                    .contentShape(Rectangle())
                            }
                            .frame(minHeight: kMinTouchTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.safeToneBackground)
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
