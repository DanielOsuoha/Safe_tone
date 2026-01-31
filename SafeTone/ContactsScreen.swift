//
//  ContactsScreen.swift
//  SafeTone
//
//  Native iOS 26 Phone layout: List + searchable + alphabetical scroll index.
//

import SwiftUI

struct ContactRow: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let initials: String
}

private let allContacts: [ContactRow] = [
    ContactRow(name: "Alice Chen", subtitle: "+1 555 0101", initials: "AC"),
    ContactRow(name: "Bob Martinez", subtitle: "+1 555 0102", initials: "BM"),
    ContactRow(name: "Carol Williams", subtitle: "+1 555 0103", initials: "CW"),
    ContactRow(name: "David Kim", subtitle: "+1 555 0104", initials: "DK"),
    ContactRow(name: "Eva Johnson", subtitle: "+1 555 0105", initials: "EJ"),
    ContactRow(name: "Frank Lee", subtitle: "+1 555 0106", initials: "FL"),
    ContactRow(name: "Grace Park", subtitle: "+1 555 0107", initials: "GP"),
    ContactRow(name: "Henry Wong", subtitle: "+1 555 0108", initials: "HW"),
]

struct ContactsScreen: View {
    @State private var searchText: String = ""

    private var filteredContacts: [ContactRow] {
        if searchText.isEmpty { return allContacts }
        return allContacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.contains(searchText)
        }
    }

    private var sections: [(letter: String, contacts: [ContactRow])] {
        let grouped = Dictionary(grouping: filteredContacts) { contact in
            String(contact.name.prefix(1)).uppercased()
        }
        return grouped.keys.sorted().map { letter in
            (letter, (grouped[letter] ?? []).sorted(by: { $0.name < $1.name }))
        }
        .filter { !$0.contacts.isEmpty }
    }

    var body: some View {
        ZStack {
            Color.safeToneDeepBlue.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Contacts")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.safeTonePureWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                List {
                    ForEach(sections, id: \.letter) { section in
                        Section {
                            ForEach(section.contacts) { contact in
                                contactRow(contact)
                                    .listRowBackground(Color.safeToneDeepBlue)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                            }
                        } header: {
                            Text(section.letter)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.safeTonePureWhite)
                                .id(section.letter)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search")
                .overlay(alignment: .trailing) {
                    sectionIndexView
                }
            }
        }
    }

    private func contactRow(_ contact: ContactRow) -> some View {
        Button {
            // Mock tap
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.safeTonePureWhite.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text(contact.initials)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.safeTonePureWhite)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.safeTonePureWhite)
                    Text(contact.subtitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.safeTonePureWhite.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.safeTonePureWhite.opacity(0.6))
            }
            .frame(minHeight: kMinTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var sectionIndexView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 2) {
                ForEach(sections.map(\.letter), id: \.self) { letter in
                    Button {
                        withAnimation {
                            proxy.scrollTo(letter, anchor: .top)
                        }
                    } label: {
                        Text(letter)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.safeTonePureWhite.opacity(0.9))
                            .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 4)
        }
    }
}

#Preview {
    ContactsScreen()
}
