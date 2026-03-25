import SwiftUI

// MARK: - Brand + Semantic Colors
//
// Used by all targets: iOS, macOS, visionOS (multiplatform), watchOS.
// Brand colors are fixed. Semantic colors adapt to platform + color scheme.

enum CricColors {
    // Brand — fixed across platforms
    static let accent = Color(hex: "#DC1F26")
    static let live   = Color(hex: "#DC1F26")
    static let t20    = Color(hex: "#E87000")
    static let test   = Color(hex: "#7C3AED")
    static let odi    = Color(hex: "#16A34A")

    // Semantic — platform-adaptive
    static var background: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #elseif os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else   // watchOS, visionOS
        Color.black
        #endif
    }

    static var surface: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #elseif os(macOS)
        Color(NSColor.underPageBackgroundColor)
        #else
        Color.black
        #endif
    }

    static var card: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(white: 0.12)
        #endif
    }

    static var cardBorder: Color {
        #if os(iOS)
        Color(UIColor.separator)
        #elseif os(macOS)
        Color(NSColor.separatorColor)
        #else
        Color(white: 0.25)
        #endif
    }
}

// MARK: - Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Match Type Color (shared across platforms)

extension Match {
    var typeColor: Color {
        switch matchType.lowercased() {
        case "t20", "t20i", "it20": return CricColors.t20
        case "test", "mdm":         return CricColors.test
        case "odi",  "odm":         return CricColors.odi
        default:                    return CricColors.accent
        }
    }
}
