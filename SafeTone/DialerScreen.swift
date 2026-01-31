//
//  DialerScreen.swift
//  SafeTone
//
//  3x4 glass-morphic keypad with Emerald Call button.
//

import SwiftUI

struct DialerScreen: View {
    var onCallTapped: (() -> Void)?
    @State private var enteredNumber: String = ""
    @State private var callPulse = false

    private let digits: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]

    var body: some View {
        ZStack {
            Color.safeToneNavy.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 24)
                // Display
                Text(enteredNumber.isEmpty ? " " : enteredNumber)
                    .font(SafeToneFonts.title2)
                    .foregroundStyle(Color.safeToneTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 24)
                Spacer().frame(height: 32)
                // 3x4 grid
                VStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 20) {
                            ForEach(0..<3, id: \.self) { col in
                                let label = digits[row][col]
                                dialButton(label: label)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                Spacer().frame(height: 28)
                // Call button (Emerald, pulse)
                callButton
                Spacer().frame(height: 40)
            }
        }
    }

    private func dialButton(label: String) -> some View {
        Button {
            enteredNumber += label
        } label: {
            Text(label)
                .font(SafeToneFonts.dialDigit)
                .foregroundStyle(Color.safeToneTextPrimary)
                .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassDroplet()
    }

    private var callButton: some View {
        Button {
            onCallTapped?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text("Call")
                    .font(SafeToneFonts.bodyBold)
            }
            .foregroundStyle(Color.safeToneNavy)
            .frame(minWidth: max(60, 200), minHeight: kMinTouchTarget)
            .padding(.horizontal, 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.safeToneEmerald)
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.safeToneEmeraldBright.opacity(0.5), Color.safeToneEmerald],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            }
            .shadow(color: Color.safeToneEmerald.opacity(0.5), radius: callPulse ? 16 : 10)
            .scaleEffect(callPulse ? 1.02 : 1.0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                callPulse = true
            }
        }
    }
}

#Preview {
    DialerScreen()
}
