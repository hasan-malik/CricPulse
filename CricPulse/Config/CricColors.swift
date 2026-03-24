import SwiftUI

enum CricColors {
    static let accent      = Color(hex: "#2997ff")
    static let background  = Color(hex: "#09090f")
    static let card        = Color(hex: "#13131e")
    static let cardBorder  = Color(hex: "#2c2c3e")
    static let live        = Color(hex: "#ff3b30")
    static let t20         = Color(hex: "#ff9f0a")
    static let test        = Color(hex: "#bf5af2")
    static let odi         = Color(hex: "#30d158")
    static let upcoming    = Color(hex: "#64d2ff")
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

    static var cricBackground: Color { CricColors.background }
    static var cricCard: Color       { CricColors.card }
    static var cricBorder: Color     { CricColors.cardBorder }
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
