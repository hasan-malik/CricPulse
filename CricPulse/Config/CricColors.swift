import SwiftUI

enum CricColors {
    static let accent      = Color(hex: "#DC1F26")   // cricket red
    static let background  = Color(hex: "#FFFFFF")   // pure white
    static let surface     = Color(hex: "#F5F6F8")   // page background
    static let card        = Color(hex: "#FFFFFF")   // white cards
    static let cardBorder  = Color(hex: "#E5E7EB")   // light border
    static let live        = Color(hex: "#DC1F26")   // red for live
    static let t20         = Color(hex: "#E87000")   // orange
    static let test        = Color(hex: "#7C3AED")   // purple
    static let odi         = Color(hex: "#16A34A")   // green
    static let upcoming    = Color(hex: "#2563EB")   // blue
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
