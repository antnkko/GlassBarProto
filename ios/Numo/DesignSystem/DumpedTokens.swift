import SwiftUI

// Tokens for the ported "Dumped ⚡" confirmation screen (Stage4_Dumped), added here as EXTENSIONS
// so no existing design-system file is touched. The screen was ported from the sibling
// `Text Dump Component Animations` project; everything else it needs already exists in this target.

extension NumoColor {
    static let vibrantDark      = Color(hex: 0x382312)  // blueRibbon vibrant dark: header + task title
    static let slackDark        = Color(hex: 0x580682)  // slack vibrant dark: routine title (purple)
    static let slackVibrant     = Color(hex: 0x7636A2)  // slack vibrant: routine glyph (lighter purple)
    static let slackHighlight   = Color(hex: 0x4EAC6C)  // slack highlight: routine when-tag (green)
    static let buttercupVibrant = Color(hex: 0xCA8700)  // buttercup vibrant: note glyph (amber)
    static let buttercupDark    = Color(hex: 0x4D3202)  // buttercup vibrant dark: note text (brown)
}

extension Metrics {
    // "Dumped ⚡" header, a ✕ to dismiss and a blue ↑ to commit. Figma frame is 402-wide;
    // absolute top offsets are converted to safe-area-relative (Figma status bar ≈ 62pt).
    enum Dumped {
        // Header ("Dumped") — Figma title y=130, status bar 62 → 68 below the safe area
        static let headerTopFromSafe: CGFloat = 68
        static let headerLeading: CGFloat = 34
        static let headerBottom: CGFloat = 28
        static let titleSize: CGFloat = 46
        static let titleTracking: CGFloat = 0.92

        // Close button (reuses Stage-3 `CloseButton`) — Figma y=82 → 20 below the safe area
        static let closeTopFromSafe: CGFloat = 20
        static let closeTrailing: CGFloat = 28

        // List card
        static let cardWidth: CGFloat = 386          // 402 − 8 each side
        static let cardRadius: CGFloat = 40
        static let cardBorderOpacity: Double = 0.05  // vibrantDark @ 5%
        static let cardShadowOpacity: Double = 0.05
        static let cardShadowBlur: CGFloat = 8        // CSS blur 16 → SwiftUI radius 8
        static let cardShadowY: CGFloat = 8

        // Item row
        static let itemPadH: CGFloat = 30
        static let itemPadV: CGFloat = 28
        static let itemIconGap: CGFloat = 16          // glyph → content
        static let itemContentGap: CGFloat = 18       // text column → when-bubble
        static let titleTagGap: CGFloat = 8           // title → tag chip
        static let glyph: CGFloat = 28
        static let glyphOpacity: Double = 0.2
        static let checkboxStroke: CGFloat = 2.875    // checkbox squircle stroke (from checkbox.svg)
        static let titleTextSize: CGFloat = 16
        static let titleLineSpacing: CGFloat = 2      // note inter-line gap → ≈ 24pt lines (Obviously-Medium 16)
        static let rowRotation: CGFloat = 0.75        // chips/bubbles tilt ±this

        // Separator (dashed)
        static let sepWidth: CGFloat = 356
        static let sepThickness: CGFloat = 1.5
        static let sepDash: [CGFloat] = [3, 4]
        static let sepColorOpacity: Double = 0.40

        // Tag chip — a plain rounded capsule with a leading dot
        static let chipPadLeading: CGFloat = 12
        static let chipPadTrailing: CGFloat = 14
        static let chipPadV: CGFloat = 5
        static let chipDot: CGFloat = 6               // leading category dot
        static let chipDotGap: CGFloat = 8            // dot → label
        static let chipTextSize: CGFloat = 14
        static let chipShadowOpacity: Double = 0.20
        static let chipShadowBlur: CGFloat = 5
        static let chipBorderOpacity: Double = 0.12

        // When-bubble (speech bubble) — Figma px-6, hugs the two-line text
        static let whenPadH: CGFloat = 6
        static let whenPadV: CGFloat = 6
        static let whenRadius: CGFloat = 11
        static let whenTextSize: CGFloat = 15
        static let whenLineSpacing: CGFloat = 1
        static let whenFillOpacity: Double = 0.18
        static let whenTail: CGFloat = 5              // little speech-bubble tail

        // Note text (line 2 overflows; right-edge fade)
        static let noteMaxWidth: CGFloat = 282
        static let noteFadeStart: Double = 0.86       // opaque → clear, leading→trailing

        // Bottom FAB (blue confirm) — FIXED at the bottom (like the ✕); content scrolls under it
        static let fabSize: CGFloat = 96
        static let fabBottom: CGFloat = 48            // from safe-area bottom (Figma ~72 from frame bottom)
        static let fabClearance: CGFloat = 24         // extra gap so the last row clears the fixed FAB
        static let fabArrowW: CGFloat = 32            // user-attached arrow SVG (32×32, stroke 3.5)
        static let fabArrowH: CGFloat = 32
        static let fabArrowStroke: CGFloat = 3.5
    }
}
