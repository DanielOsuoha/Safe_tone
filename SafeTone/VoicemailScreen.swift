//
//  VoicemailScreen.swift
//  SafeTone
//
//  Native Phone-style Voicemail list. Black background, 17pt body.
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
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Voicemail")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(mockVoicemails) { item in
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
                                        Text(item.detail)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundStyle(Color(UIColor.systemGray))
                                    }
                                    Spacer()
                                    Text(item.duration)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(Color(UIColor.systemGray))
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
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
    VoicemailScreen()
}
