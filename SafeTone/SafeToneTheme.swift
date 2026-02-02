//
//  SafeToneTheme.swift
//  SafeTone
//
//  Native iPhone Phone app theme: Pure Black background, SF Pro typography.
//

import SwiftUI

// MARK: - Colors (standard system; primary background Pure Black)
extension Color {
    static let safeToneBackground = Color.black
    static let safeToneTextPrimary = Color.white
    static let safeToneTextSecondary = Color.gray
    static let safeToneEmerald = Color(red: 0.2, green: 0.78, blue: 0.35)    
    static let safeToneGlassHighlight = Color.white
}

struct SafeToneFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodySemibold = Font.system(size: 17, weight: .semibold)
    static let tabLabel = Font.system(size: 10, weight: .medium)
}

let kMinTouchTarget: CGFloat = 60
