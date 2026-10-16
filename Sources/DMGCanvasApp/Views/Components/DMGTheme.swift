import SwiftUI
import AppKit

public struct DMGTheme {
    // MARK: - Inverted Dark Gray Surface Colors
    
    /// Top toolbar & header area: darker tone (black/dark background: #111113)
    public static let barBackground = Color(hex: 0x111113)
    public static let headerBackground = Color(hex: 0x111113)
    
    /// Main window detail area: lighter dark-gray tone: #212124
    public static let background = Color(hex: 0x212124)
    
    /// Left sidebar & inspector background: lighter dark-gray tone: #252528
    public static let sidebar = Color(hex: 0x252528)
    
    /// Card / Container surface: #2d2d31
    public static let surface = Color(hex: 0x2d2d31)
    
    /// Elevated cards / controls: #36363b
    public static let surfaceElevated = Color(hex: 0x36363b)
    
    /// Input field background: #222225
    public static let inputBackground = Color(hex: 0x222225)
    
    /// Canvas Desk backdrop (behind 540x350 window): #19191c
    public static let canvasDesk = Color(hex: 0x19191c)
    
    // MARK: - Borders & Dividers
    
    /// Subtle matching border contrast: #3b3b40
    public static let border = Color(hex: 0x3b3b40)
    
    /// Card border: #43434a
    public static let cardBorder = Color(hex: 0x43434a)
    
    /// Subtle divider: #333338
    public static let divider = Color(hex: 0x333338)
    
    // MARK: - Crisp Light Typography
    
    /// Primary crisp text: #f7f7f9
    public static let textPrimary = Color(hex: 0xf7f7f9)
    
    /// Secondary text: #a8a8b2
    public static let textSecondary = Color(hex: 0xa8a8b2)
    
    /// Muted caption text: #7a7a85
    public static let textMuted = Color(hex: 0x7a7a85)
    
    // MARK: - Accents
    
    /// DMGEKI Signature Sky Blue: #27A3F5 (Exact branding color)
    public static let accent = Color(red: 39.0 / 255.0, green: 163.0 / 255.0, blue: 245.0 / 255.0)
    
    /// Emerald Success
    public static let success = Color(red: 52 / 255.0, green: 199 / 255.0, blue: 89 / 255.0)
    
    /// Crimson Alert / Delete
    public static let danger = Color(red: 255 / 255.0, green: 69 / 255.0, blue: 58 / 255.0)
}

// MARK: - Color Hex Initializer Extension
extension Color {
    public init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public init(hexString: String, defaultColor: Color = .black) {
        let clean = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&int) else {
            self = defaultColor
            return
        }
        let r, g, b, a: Double
        switch clean.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (
                Double((int >> 8) * 17) / 255.0,
                Double((int >> 4 & 0xF) * 17) / 255.0,
                Double((int & 0xF) * 17) / 255.0,
                1.0
            )
        case 6: // RGB (24-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                1.0
            )
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                Double((int >> 24) & 0xFF) / 255.0
            )
        default:
            self = defaultColor
            return
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    public func toHex() -> String {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        let r = Int(round(rgb.redComponent * 255.0))
        let g = Int(round(rgb.greenComponent * 255.0))
        let b = Int(round(rgb.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
