//
//  RecentsScreen.swift
//  SafeTone
//
//  Native iPhone Recents: standard List, blue info.circle on the right, missed calls in Red.
//

import SwiftUI

struct RecentItem: Identifiable {
    let id = UUID()
    let name: String
    let callType: String
    let timestamp: String
    let isMissed: Bool
}

struct RecentSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [RecentItem]
}

private let mockRecentSections: [RecentSection] = [
    RecentSection(title: "Today", items: [
        RecentItem(name: "Mom", callType: "iPhone", timestamp: "2:34 PM", isMissed: false)
    ]),
    RecentSection(title: "Yesterday", items: [
        RecentItem(name: "Alice Chen", callType: "mobile", timestamp: "8:15 PM", isMissed: false),
        RecentItem(name: "Unknown", callType: "mobile", timestamp: "3:22 PM", isMissed: true)
    ]),
    RecentSection(title: "Last Week", items: [
        RecentItem(name: "+1 (555) 987-6543", callType: "iPhone", timestamp: "Mon", isMissed: true),
        RecentItem(name: "David Park", callType: "mobile", timestamp: "Sun", isMissed: false),
        RecentItem(name: "+1 (555) 234-5678", callType: "iPhone", timestamp: "Sat", isMissed: false)
    ])
]

struct RecentsScreen: View {
    @EnvironmentObject private var callManager: CallManager

    private var recentSections: [RecentSection] {
        guard let mostRecentCall = callManager.mostRecentCall else {
            return mockRecentSections
        }

        var sections = mockRecentSections
        let latestItem = RecentItem(
            name: ContactDirectory.displayName(for: mostRecentCall.handle),
            callType: mostRecentCall.direction == .incoming ? "incoming" : "outgoing",
            timestamp: Self.timestampFormatter.string(from: mostRecentCall.timestamp),
            isMissed: mostRecentCall.wasMissed
        )

        if let todayIndex = sections.firstIndex(where: { $0.title == "Today" }) {
            let existingItems = sections[todayIndex].items.filter { $0.name != latestItem.name || $0.timestamp != latestItem.timestamp }
            sections[todayIndex] = RecentSection(title: "Today", items: [latestItem] + existingItems)
        } else {
            sections.insert(RecentSection(title: "Today", items: [latestItem]), at: 0)
        }

        return sections
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Recents")
                    .font(SafeToneFonts.largeTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                List {
                    ForEach(recentSections) { section in
                        Section {
                            ForEach(section.items) { item in
                                recentRow(item)
                                    .listRowBackground(Color.black)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                            }
                        } header: {
                            Text(section.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .textCase(nil)
                                .padding(.top, section.title == "Today" ? 0 : 12)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
            // Demo Call Button (bottom right corner)
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: 12) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

                        if callManager.localAudioStreamManager.isPlayingRecording {
                            callManager.localAudioStreamManager.stopPlayback()
                        } else {
                            callManager.localAudioStreamManager.playLastRecording()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: callManager.localAudioStreamManager.isPlayingRecording ? "stop.fill" : "play.fill")
                            Text(callManager.localAudioStreamManager.isPlayingRecording ? "Stop" : "Play Recording")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(callManager.localAudioStreamManager.hasRecording ? 0.16 : 0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(callManager.localAudioStreamManager.hasRecording ? 0.65 : 0.25), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!callManager.localAudioStreamManager.hasRecording)
                    .opacity(callManager.localAudioStreamManager.hasRecording ? 1 : 0.45)
                    .padding(.leading, 24)

                    Spacer()

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        callManager.receiveIncomingCall(handle: "+1 555 0101")
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 38, height: 38)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(0.8)
                    .padding(.trailing, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func recentRow(_ item: RecentItem) -> some View {
        Button {
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Text(item.timestamp)
                    .font(SafeToneFonts.body)
                    .foregroundStyle(Color(UIColor.systemGray))
                    .frame(width: 80, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(item.isMissed ? Color.red : .white)
                    Text(item.callType)
                        .font(SafeToneFonts.body)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
                Spacer()
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
    }
}

#Preview {
    RecentsScreen()
        .environmentObject(CallManager.shared)
}
