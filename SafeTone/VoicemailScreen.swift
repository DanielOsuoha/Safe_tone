//
//  VoicemailScreen.swift
//  SafeTone
//
//  Native iOS 26 Phone layout. Solid Deep Blue, Pure White, 60pt touch targets.
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
            Color.safeToneDeepBlue.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Voicemail")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.safeTonePureWhite)
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
                                    Text(item.detail)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(Color.safeTonePureWhite.opacity(0.8))
                                }
                                Spacer()
                                Text(item.duration)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Color.safeTonePureWhite.opacity(0.8))
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.safeTonePureWhite)
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
    VoicemailScreen()
}
