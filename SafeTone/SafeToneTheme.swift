//
//  SafeToneTheme.swift
//  SafeTone
//
//  Liquid Glass design tokens — Dark Navy base, senior-readable typography.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let safeToneNavy = Color(hex: "1A237E")
    static let safeToneNavyLight = Color(hex: "283593")
    static let safeToneNavySoft = Color(hex: "3949AB")
    static let safeToneEmerald = Color(hex: "00C853")
    static let safeToneEmeraldBright = Color(hex: "69F0AE")
    static let safeToneScamRed = Color(hex: "FF1744")
    static let safeToneScamRedSoft = Color(hex: "FF5252")
    static let safeToneVerifiedGreen = Color(hex: "00E676")
    static let safeToneGlassWhite = Color.white.opacity(0.25)
    static let safeToneGlassHighlight = Color.white.opacity(0.45)
    static let safeToneTextPrimary = Color.white
    static let safeToneTextSecondary = Color.white.opacity(0.85)
    static let safeToneHighContrast = Color.white

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography (18pt+ body for senior readability)
struct SafeToneFonts {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 22, weight: .semibold)
    static let title2 = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 18, weight: .regular)
    static let bodyBold = Font.system(size: 18, weight: .semibold)
    static let callout = Font.system(size: 20, weight: .medium)
    static let dialDigit = Font.system(size: 28, weight: .light)
    static let tabLabel = Font.system(size: 11, weight: .medium)
}

// MARK: - Touch target (60x60 minimum)
let kMinTouchTarget: CGFloat = 60

// MARK: - Glass droplet modifier
struct GlassDropletStyle: ViewModifier {
    var tint: Color = .safeToneGlassWhite
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.4), tint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.safeToneGlassHighlight.opacity(0.6), lineWidth: 1)
                }
            )
    }
}

extension View {
    func glassDroplet(tint: Color = .safeToneGlassWhite) -> some View {
        modifier(GlassDropletStyle(tint: tint))
    }
}
