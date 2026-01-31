//
//  VoicemailScreen.swift
//  SafeTone
//
//  Native iPhone Voicemail: standard List, blue info.circle on the right.
//

import SwiftUI

struct VoicemailItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let duration: String
}

private let mockVoicemails: [VoicemailItem] = [
    VoicemailItem(name: "Alice Chen", detail: "Today, 2:34 PM", duration: "0:45"),
    VoicemailItem(name: "Unknown", detail: "Yesterday", duration: "1:20"),
]

struct VoicemailScreen: View {
    var body: some View {
        ZStack {
            Color.safeToneBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Voicemail")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                List {
                    ForEach(mockVoicemails) { item in
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
                                    Text(item.detail)
                                        .font(SafeToneFonts.body)
                                        .foregroundStyle(Color(UIColor.systemGray))
                                }
                                Spacer()
                                Text(item.duration)
                                    .font(SafeToneFonts.body)
                                    .foregroundStyle(Color(UIColor.systemGray))
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
    VoicemailScreen()
}
