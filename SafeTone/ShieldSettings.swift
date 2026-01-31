//
//  ShieldSettings.swift
//  SafeTone
//
//  Dashboard with System Guard toggle and high-visibility status cards.
//

import SwiftUI

struct ShieldSettings: View {
    var onScrollOffset: ((CGFloat) -> Void)?
    @State private var systemGuardActive: Bool = true

    var body: some View {
        ZStack {
            Color.safeToneNavy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Shield")
                        .font(SafeToneFonts.largeTitle)
                        .foregroundStyle(Color.safeToneTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    systemGuardCard
                    statusCard(
                        title: "Call Verification",
                        subtitle: "Verified calls show a green shield.",
                        icon: "checkmark.shield.fill",
                        color: Color.safeToneVerifiedGreen
                    )
                    statusCard(
                        title: "Scam Warnings",
                        subtitle: "Suspected scams show a red warning.",
                        icon: "exclamationmark.shield.fill",
                        color: Color.safeToneScamRed
                    )
                    statusCard(
                        title: "Block List",
                        subtitle: "Blocked numbers never ring.",
                        icon: "hand.raised.fill",
                        color: Color.safeToneNavySoft
                    )
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
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

    private var systemGuardCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(systemGuardActive ? Color.safeToneVerifiedGreen : Color.safeToneTextSecondary)
                Text("System Guard")
                    .font(SafeToneFonts.title2)
                    .foregroundStyle(Color.safeToneTextPrimary)
                Spacer()
            }
            Text("Protect your calls with real-time verification.")
                .font(SafeToneFonts.body)
                .foregroundStyle(Color.safeToneTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Text("Active")
                    .font(SafeToneFonts.bodyBold)
                    .foregroundStyle(Color.safeToneTextPrimary)
                Spacer()
                Toggle("", isOn: $systemGuardActive)
                    .labelsHidden()
                    .tint(Color.safeToneEmerald)
                    .frame(minWidth: 60, minHeight: kMinTouchTarget)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.safeToneGlassWhite.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.safeToneGlassHighlight.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func statusCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SafeToneFonts.bodyBold)
                    .foregroundStyle(Color.safeToneTextPrimary)
                Text(subtitle)
                    .font(SafeToneFonts.body)
                    .foregroundStyle(Color.safeToneTextSecondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.safeToneGlassWhite.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.safeToneGlassHighlight.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ShieldSettings()
}
