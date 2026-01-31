//
//  ShieldSettings.swift
//  SafeTone
//
//  Dashboard with System Guard toggle. Black background, system typography.
//

import SwiftUI

struct ShieldSettings: View {
    @State private var systemGuardActive: Bool = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Shield")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    systemGuardCard
                    statusCard(
                        title: "Call Verification",
                        subtitle: "Verified calls show a green shield.",
                        icon: "checkmark.shield.fill",
                        color: Color.green
                    )
                    statusCard(
                        title: "Scam Warnings",
                        subtitle: "Suspected scams show a red warning.",
                        icon: "exclamationmark.shield.fill",
                        color: Color.red
                    )
                    statusCard(
                        title: "Block List",
                        subtitle: "Blocked numbers never ring.",
                        icon: "hand.raised.fill",
                        color: Color(UIColor.systemGray2)
                    )
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var systemGuardCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(systemGuardActive ? Color.green : Color(UIColor.systemGray))
                Text("System Guard")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            Text("Protect your calls with real-time verification.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color(UIColor.systemGray))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Text("Active")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: $systemGuardActive)
                    .labelsHidden()
                    .tint(Color.green)
                    .frame(minWidth: 60, minHeight: 60)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6).opacity(0.3))
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(UIColor.systemGray))
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6).opacity(0.3))
        )
    }
}

#Preview {
    ShieldSettings()
}
