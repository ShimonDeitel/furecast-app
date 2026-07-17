import SwiftUI

/// Sage green + warm coral/salmon, organic and playful — deliberately the opposite of this
/// batch's rigid grids/rings (Vantage's graphite linework, Dossier's scrapbook cards, etc).
/// Furecast owns soft, rounded, paw-print-derived blobs throughout.
enum FurecastColor {
    static let canvas = Color(light: Color(hex: 0xF1F5EA), dark: Color(hex: 0x172019))
    static let panel = Color(light: Color(hex: 0xFCFDF8), dark: Color(hex: 0x212B22))
    static let ink = Color(light: Color(hex: 0x25332A), dark: Color(hex: 0xF0F5EC))
    static let inkMuted = Color(light: Color(hex: 0x687568), dark: Color(hex: 0x9EAE9C))
    static let hairline = Color(light: Color(hex: 0xDFE7D6), dark: Color(hex: 0x2E3A2E))

    /// Primary CTA / actual-spend fill.
    static let coral = Color(hex: 0xFF7A5C)
    static let coralDeep = Color(hex: 0xDE5B3E)
    /// Predicted-line marker + secondary accents — the "sage" half of the palette.
    static let sage = Color(hex: 0x6E9C74)
    static let sageDeep = Color(hex: 0x4C7A52)
    /// Surprise jar — a warm amber that visually separates flagged-risk dollars from
    /// everything else in the app.
    static let jarAmber = Color(hex: 0xE3A23A)
}

enum FurecastFont {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func value(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func tag(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
