//
//  SafeToneTheme.swift
//  SafeTone
//
//  Native iPhone Phone app theme: Pure Black background, SF Pro typography.
//

import SwiftUI

// MARK: - Colors (standard system; primary background Pure Black)
extension Color {
    /// Primary background — Pure Black (#000000).
    static let safeToneBackground = Color.black
}

// MARK: - Typography (SF Pro: Large Title 34pt, body 17pt)
struct SafeToneFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodySemibold = Font.system(size: 17, weight: .semibold)
}

// MARK: - Touch target (60×60 minimum for accessibility)
let kMinTouchTarget: CGFloat = 60
