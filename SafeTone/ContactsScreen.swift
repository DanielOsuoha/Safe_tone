//
//  ContactsScreen.swift
//  SafeTone
//
//  High-contrast list with large avatars.
//

import SwiftUI

struct ContactRow: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let initials: String
}

private let mockContacts: [ContactRow] = [
    ContactRow(name: "Alice Chen", subtitle: "+1 555 0101", initials: "AC"),
    ContactRow(name: "Bob Martinez", subtitle: "+1 555 0102", initials: "BM"),
    ContactRow(name: "Carol Williams", subtitle: "+1 555 0103", initials: "CW"),
    ContactRow(name: "David Kim", subtitle: "+1 555 0104", initials: "DK"),
    ContactRow(name: "Eva Johnson", subtitle: "+1 555 0105", initials: "EJ"),
]

struct ContactsScreen: View {
    var onScrollOffset: ((CGFloat) -> Void)?

    var body: some View {
        ZStack {
            Color.safeToneNavy.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Contacts")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(Color.safeToneTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mockContacts) { contact in
                            contactRow(contact)
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

    private func contactRow(_ contact: ContactRow) -> some View {
        Button {
            // Mock tap
        } label: {
            HStack(spacing: 16) {
                // Large avatar (60pt min for touch; visual circle larger)
                ZStack {
                    Circle()
                        .fill(Color.safeToneNavySoft)
                        .frame(width: 64, height: 64)
                    Text(contact.initials)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.safeToneTextPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(SafeToneFonts.bodyBold)
                        .foregroundStyle(Color.safeToneTextPrimary)
                    Text(contact.subtitle)
                        .font(SafeToneFonts.body)
                        .foregroundStyle(Color.safeToneTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.safeToneTextSecondary)
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
    ContactsScreen()
}
