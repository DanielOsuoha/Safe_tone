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
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Text("Verified")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isVerified ? Color.green : Color(UIColor.systemGray))
                    Toggle("", isOn: $isVerified)
                        .labelsHidden()
                        .tint(Color.green)
                        .frame(width: 60, height: 60)
                    Text("Scam Warning")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(!isVerified ? Color.red : Color(UIColor.systemGray))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                Spacer().frame(height: 40)
                Text("+1 (555) 123-4567")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Text("In Call")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(UIColor.systemGray))
                    .padding(.top, 4)
                Spacer().frame(height: 48)
                shieldGraphic
                Spacer().frame(height: 48)
                Button {
                    // Mock only
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .background(Circle().fill(Color.red))
                Spacer().frame(height: 60)
            }
        }
    }

    private var shieldGraphic: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 48)
                .fill(accentColor.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 30)
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
        isVerified ? Color.green : Color.red
    }
}

#Preview {
    LiveCallMockup()
}
