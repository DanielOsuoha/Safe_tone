//
//  DialerScreen.swift
//  SafeTone
//
//  Native iPhone keypad: systemGray6 circular buttons, white text, 3×4 grid, standard Apple Green call button.
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
            Color.safeToneBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                    Text(enteredNumber.isEmpty ? " " : enteredNumber)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.white)
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
                    .foregroundStyle(.white)
                if let letters = key.letters {
                    Text(letters)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(UIColor.systemGray))
                }
            }
            .frame(width: 78, height: 78)
            .contentShape(Circle())
        }
        .buttonStyle(DialKeyButtonStyle())
    }

    private var callButton: some View {
        Button {
            onCallTapped?()
        } label: {
            Image(systemName: "phone.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 78, height: 78)
                .contentShape(Circle())
        }
        .buttonStyle(CallKeyButtonStyle())
    }
}

// MARK: - Dial key: systemGray6 circle, white text (no custom glass)
struct DialKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Circle().fill(Color(UIColor.systemGray6)))
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Call key: standard Apple Green circle
struct CallKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Circle().fill(Color.green))
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    DialerScreen()
}
