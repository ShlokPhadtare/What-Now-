//
//  Theme.swift
//  What Now?
//

import SwiftUI

/// Design tokens and helpers for the What Now? design system.
///
/// Uses semantic Apple colors augmented with branded accent colors.
/// All colors adapt automatically to dark/light mode.
enum WNTheme {

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }

    // MARK: - Shadows
    // Removed heavy drop shadows for a flatter, native look.

    // MARK: - Fonts

    enum Fonts {
        static let largeTitle = Font.largeTitle.weight(.medium)
        static let title = Font.title2.weight(.medium)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let timer = Font.system(size: 64, weight: .ultraLight, design: .rounded)
        static let timerSmall = Font.system(size: 32, weight: .light, design: .rounded)
    }

    // MARK: - Color from Hex

    /// Convert a hex string (e.g. "#FF2D55") to a SwiftUI `Color`.
    static func color(hex: String) -> Color {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Category Color Extension

extension WNCategory {
    /// The SwiftUI color derived from `colorHex`.
    var color: Color {
        WNTheme.color(hex: colorHex)
    }
}

// MARK: - Priority Color Extension

extension TaskPriority {
    var color: Color {
        switch self {
        case .low: Color.secondary
        case .medium: Color.blue
        case .high: Color.orange
        case .critical: Color.red
        }
    }
}

// MARK: - Reusable Modifiers

extension View {
    /// Subtle background for grouping without heavy rounded rects.
    func wnCard() -> some View {
        self
            .padding(WNTheme.Spacing.md)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: WNTheme.Radius.md))
    }

    /// Section header style.
    func wnSectionHeader() -> some View {
        self
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }
}
