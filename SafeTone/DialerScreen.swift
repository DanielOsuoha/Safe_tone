//
//  DialerScreen.swift
//  SafeTone
//
//  Native iOS 26 keypad: Light Blue/White frosted glass circles, 3×4 grid, Emerald call button.
//

import SwiftUI

private struct DialKey: Identifiable {
    let id: String
    let digit: String
    let letters: String?
}

private let keypadRows: [[DialKey]] = [
    [DialKey(id: "1", digit: "1", letters: nil),
     DialKey(id: "2", digit: "2", letters: "ABC"),
     DialKey(id: "3", digit: "3", letters: "DEF")],
    [DialKey(id: "4", digit: "4", letters: "GHI"),
     DialKey(id: "5", digit: "5", letters: "JKL"),
     DialKey(id: "6", digit: "6", letters: "MNO")],
    [DialKey(id: "7", digit: "7", letters: "PQRS"),
     DialKey(id: "8", digit: "8", letters: "TUV"),
     DialKey(id: "9", digit: "9", letters: "WXYZ")],
    [DialKey(id: "*", digit: "*", letters: nil),
     DialKey(id: "0", digit: "0", letters: "+"),
     DialKey(id: "#", digit: "#", letters: nil)],
]

struct DialerScreen: View {
    var onCallTapped: (() -> Void)?
    @State private var enteredNumber: String = ""

    var body: some View {
        ZStack {
            Color.safeToneDeepBlue.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.safeTonePureWhite)
                    Text(enteredNumber.isEmpty ? " " : enteredNumber)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.safeTonePureWhite)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: 44)
                Spacer().frame(height: 24)
                VStack(spacing: 18) {
                    ForEach(Array(keypadRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 18) {
                            ForEach(row) { key in
                                dialButton(key: key)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                Spacer().frame(height: 20)
                callButton
                Spacer().frame(height: 40)
            }
        }
    }

    private func dialButton(key: DialKey) -> some View {
        Button {
            enteredNumber += key.digit
        } label: {
            VStack(spacing: 2) {
                Text(key.digit)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.safeTonePureWhite)
                if let letters = key.letters {
                    Text(letters)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.safeTonePureWhite.opacity(0.8))
                }
            }
            .frame(width: 78, height: 78)
            .contentShape(Circle())
        }
        .buttonStyle(FrostedDialKeyButtonStyle())
    }

    private var callButton: some View {
        Button {
            onCallTapped?()
        } label: {
            Image(systemName: "phone.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.safeTonePureWhite)
                .frame(width: 78, height: 78)
                .contentShape(Circle())
        }
        .buttonStyle(EmeraldCallKeyButtonStyle())
    }
}

// MARK: - Frosted glass dial key (Light Blue/White refraction, 60pt+ touch)
struct FrostedDialKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Large Emerald Green call button
struct EmeraldCallKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Circle().fill(Color.safeToneEmerald))
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    DialerScreen()
}
