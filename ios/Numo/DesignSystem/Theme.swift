import SwiftUI

extension Color {
    /// 0xRRGGBB
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Color tokens mirroring the RN theme (default skin `blueRibbon`, light mode).
/// Source of truth: `../RN Codebase/src/features/theme/{palette,skins,lightTheme}.ts`.
enum NumoColor {
    // blueRibbon skin
    static let vibrant       = Color(hex: 0xF65D00)   // accent: bg, FAB, "Public"
    static let vibrantLight  = Color(hex: 0xFFB58A)
    static let skinLight     = Color(hex: 0xFFF2ED)   // skin "light": pill bg

    // palette / semantic
    static let white         = Color.white
    static let text          = Color.black
    static let grayAlmost    = Color(hex: 0xF1F1F1)   // back-button bg
    static let grayNormal    = Color(hex: 0xC1C3C6)   // placeholder
    static let grayDarkish   = Color(hex: 0x4E4E4E)   // back chevron
    static let grayNight     = Color(hex: 0x888A8E)   // unselected tag text; home month label
    static let grayMuted     = Color(hex: 0x9CA3AF)
    static let black         = Color.black

    // Home screen (DoScreen port) — additive, blueRibbon skin
    static let highlight     = Color(hex: 0xDB7732)   // today/streak dot; redesign cursor
    static let grayMutedCool = Color(hex: 0xC1C2C6)   // date-cell text + border (≠ grayMuted #9CA3AF)
    static let tabInactive   = Color(hex: 0xB9B9B9)   // inactive tab tint

    // Stage 3 redesign (Figma 1128:14564) — additive, "neutral" ramp
    static let neutralDark   = Color(hex: 0x4B4E52)   // pill label + eyes/tag icons (≠ grayDarkish #4E4E4E)
    static let ink           = Color(hex: 0x030303)   // routine/when chip labels
}
