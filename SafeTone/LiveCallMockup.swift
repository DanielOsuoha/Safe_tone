//
//  LiveCallMockup.swift
//  SafeTone
//
//  During-call screen with Security Shield and Verified / Scam toggle.
//

import SwiftUI

struct LiveCallMockup: View {
    @State private var isVerified: Bool = true

    var body: some View {
        ZStack {
            Color.safeToneNavy.ignoresSafeArea()
            VStack(spacing: 0) {
                // Toggle: Verified (green) vs Scam Warning (red)
                HStack(spacing: 16) {
                    Text("Verified")
                        .font(SafeToneFonts.bodyBold)
                        .foregroundStyle(isVerified ? Color.safeToneVerifiedGreen : Color.safeToneTextSecondary)
                    Toggle("", isOn: $isVerified)
                        .labelsHidden()
                        .tint(Color.safeToneEmerald)
                        .frame(width: 60, height: kMinTouchTarget)
                    Text("Scam Warning")
                        .font(SafeToneFonts.bodyBold)
                        .foregroundStyle(!isVerified ? Color.safeToneScamRed : Color.safeToneTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                Spacer().frame(height: 40)
                // Caller label
                Text("+1 (555) 123-4567")
                    .font(SafeToneFonts.title2)
                    .foregroundStyle(Color.safeToneTextPrimary)
                Text("In Call")
                    .font(SafeToneFonts.body)
                    .foregroundStyle(Color.safeToneTextSecondary)
                    .padding(.top, 4)
                Spacer().frame(height: 48)
                // Large Security Shield
                shieldGraphic
                Spacer().frame(height: 48)
                // End call button
                Button {
                    // Mock only
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                        .frame(width: 72, height: 72)
                        .background(Circle().fill(Color.safeToneScamRed))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer().frame(height: 60)
            }
        }
    }

    private var shieldGraphic: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 48)
                .fill(accentColor.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 30)
            // Shield shape (SF Symbol scaled)
            Image(systemName: "shield.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.9), accentColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Image(systemName: isVerified ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .offset(y: -8),
                    alignment: .center
                )
        }
    }

    private var accentColor: Color {
        isVerified ? Color.safeToneVerifiedGreen : Color.safeToneScamRed
    }
}

#Preview {
    LiveCallMockup()
}
