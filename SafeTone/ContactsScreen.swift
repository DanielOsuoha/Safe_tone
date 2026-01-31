//
//  ContactsScreen.swift
//  SafeTone
//
//  Native Phone-style Contacts list. Black background, 17pt SF Pro body.
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
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Contacts")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(mockContacts) { contact in
                            Button {
                                // Mock tap
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(UIColor.systemGray4))
                                            .frame(width: 48, height: 48)
                                        Text(contact.initials)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundStyle(.white)
                                        Text(contact.subtitle)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundStyle(Color(UIColor.systemGray))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(UIColor.systemGray3))
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
    ContactsScreen()
}
