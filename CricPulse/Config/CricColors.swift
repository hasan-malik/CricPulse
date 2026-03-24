import SwiftUI

enum CricColors {
    // Brand colors — fixed in both light & dark
    static let accent = Color(hex: "#DC1F26")
    static let live   = Color(hex: "#DC1F26")
    static let t20    = Color(hex: "#E87000")
    static let test   = Color(hex: "#7C3AED")
    static let odi    = Color(hex: "#16A34A")

    // Adaptive — automatically flip with system color scheme
    static var background: Color {
        #if os(iOS) || os(watchOS)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var surface: Color {
        #if os(iOS) || os(watchOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.underPageBackgroundColor)
        #endif
    }

    static var card: Color {
        #if os(iOS) || os(watchOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }

    static var cardBorder: Color {
        #if os(iOS) || os(watchOS)
        Color(UIColor.separator)
        #else
        Color(NSColor.separatorColor)
        #endif
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Match {
    var typeColor: Color {
        switch matchType.lowercased() {
        case "t20", "t20i": return CricColors.t20
        case "test":        return CricColors.test
        case "odi":         return CricColors.odi
        default:            return CricColors.accent
        }
    }
}
