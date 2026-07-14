import SwiftUI

private typealias D = Metrics.Dumped

/// Constants for the Dumped screen's loading entrance. Order: ✕ flies up from below + bounces →
/// title appears, then morphs "Dumping" → "Dumped" via the native numericText transition (see
/// `DumpedScreen.header`) → card slides up → each item's children cascade → separators.
enum DumpedEntrance {
    static let blur: CGFloat = 6              // initial blur radius for a revealing element
    static let slide: CGFloat = 12            // element slide-up distance
    static let cardSlide: CGFloat = 34        // the card's short slide-up (not from screen bottom)
    static let spring: Animation = .spring(response: 0.42, dampingFraction: 0.86)

    /// Background renders immediately; the whole entrance waits this long, then plays.
    static let startDelay: Double = 1.0

    // ✕ — flies up into its point from BELOW and bounces (first thing after the pause)
    static let closeDelay: Double = 0.0
    static let closeFly = CGSize(width: 0, height: 70)     // clear travel up from below
    static let closeScaleFrom: CGFloat = 0.7
    static let closeSpring: Animation = .spring(response: 0.55, dampingFraction: 0.5)  // visible rise + bounce

    // Delay schedule (seconds from appear)
    static let chromeDelay: Double = 0.12     // FAB fade-in
    static let titleStart: Double = 0.50      // title begins after the ✕ has landed
    static let letterStep: Double = 0.05      // per-letter cadence for the title's letter-by-letter entrance
    static let cardDelay: Double = 1.10       // card slides up (after the title)
    static let itemsStart: Double = 1.50      // first item's glyph
    static let itemStride: Double = 0.62      // between items
    static let childStagger: Double = 0.10    // glyph → name → tag → when
    static let sepOffset: Double = 0.45       // separator after an item's children
    static let morphDelay: Double = 3.5       // "loading" hold: "Dumping" + dots + spinner before morphing to "Dumped"
    static let dotStep: Double = 0.33         // per-dot cadence for the loading "..." cycle (in-text periods)

    static let titleLift: CGFloat = 11        // seat the title glyph at the Figma baseline

    // Native numericText title spring — live-tunable defaults (see DumpedScreen's dev panel).
    static let titleResponse: Double = 0.4
    static let titleDamping: Double = 0.6

    // Letter-by-letter entrance bounce (LetterBounceRenderer).
    static let bounceSlide: CGFloat = 20       // each glyph starts this far below → springs up to 0
    static let entranceSettle: Double = 0.8    // time for the last glyph to finish bouncing (after its start)
}

extension View {
    /// Reveal this view (blur + opacity + short slide-up → resting) when `appeared` flips true,
    /// after `delay`. Layout-neutral (offset/blur are render transforms).
    func reveal(_ appeared: Bool, delay: Double,
                blur: CGFloat = DumpedEntrance.blur,
                slide: CGFloat = DumpedEntrance.slide) -> some View {
        modifier(RevealModifier(appeared: appeared, delay: delay, blur: blur, slide: slide))
    }

    /// The ✕ entrance: flies in from an offset + scales up + bounces (low-damping spring).
    func closeFly(_ appeared: Bool, delay: Double) -> some View {
        modifier(CloseFlyModifier(appeared: appeared, delay: delay))
    }
}

private struct RevealModifier: ViewModifier {
    let appeared: Bool
    let delay: Double
    let blur: CGFloat
    let slide: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: appeared ? 0 : blur)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : slide)
            .animation(DumpedEntrance.spring.delay(delay), value: appeared)
    }
}

private struct CloseFlyModifier: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : DumpedEntrance.closeScaleFrom)
            .offset(x: appeared ? 0 : DumpedEntrance.closeFly.width,
                    y: appeared ? 0 : DumpedEntrance.closeFly.height)
            .opacity(appeared ? 1 : 0)
            .animation(DumpedEntrance.closeSpring.delay(delay), value: appeared)
    }
}

// MARK: - Title styling

/// Shared title text styling (font + tracking + color), used by the numericText title `Text`.
extension View {
    func titleStyle() -> some View {
        font(NumoFont.obviouslyNarrowBold(Metrics.Dumped.titleSize))
            .tracking(Metrics.Dumped.titleTracking)
            .foregroundStyle(NumoColor.vibrantDark)
            .fixedSize()
    }
}

// MARK: - Letter-by-letter entrance bounce (TextRenderer)

/// Reveals a title one glyph at a time, each rolling up from below and BOUNCING in independently. One
/// `elapsedTime` advances continuously; each glyph derives its own spring from its stagger (`step`), so every
/// letter's bounce runs to completion uninterrupted while letters overlap (stays quick). The font lays the word
/// out as one run, so kerning is exact. The bounce comes from the live `response`/`damping` (the dev sliders).
struct LetterBounceRenderer: TextRenderer, Animatable {
    var elapsedTime: TimeInterval
    let step: TimeInterval       // per-letter stagger (= letterStep)
    let slide: CGFloat           // each glyph starts this far below → springs up to 0
    let response: Double
    let damping: Double

    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    private var spring: Spring { Spring(response: response, dampingRatio: damping) }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { $0 }.flatMap { $0 }
        for (i, slice) in slices.enumerated() {
            let t = elapsedTime - Double(i) * step
            if t <= 0 { continue }                                   // glyph hasn't started → hidden
            var c = context
            // Rolls up from `slide` (below) to 0, overshooting (bounce) per the spring's damping.
            let y = CGFloat(spring.value(fromValue: Double(slide), toValue: 0, initialVelocity: 0, time: t))
            c.translateBy(x: 0, y: y)
            c.opacity = min(1, t / 0.10)                             // quick fade-in
            let blur = 3 * max(0, 1 - t / 0.18)                      // subtle motion blur → sharp (numericText look)
            if blur > 0.01 { c.addFilter(.blur(radius: blur)) }
            c.draw(slice)
        }
    }
}
