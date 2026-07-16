import SwiftUI

private typealias R = Metrics.Redesign

/// "Public 👀 | 🏷" capsule — publicity selector + tags entry combined.
/// Redesign counterpart of Stage 1's `PublicityPill` (Figma 1070:1720).
struct PublicityTagsPill: View {
    /// Bare = content only, no ghost surface — the Liquid Glass chrome in
    /// `RedesignedScreen` owns the surface (material + stroke + shadow).
    var bare: Bool = false

    /// Auto-detected tag shown after the 🏷 icon (Figma 3787:9660). Owned by the
    /// screen (typing-pause debounce); the pill only renders it. Toggle inside
    /// `withAnimation(MorphChoreo.placeholderSwap)` so the blur-in and the
    /// capsule's width growth ride the same spring as every other pill swap.
    var tag: String? = nil

    @State private var isPublic = true
    @State private var tapCount = 0

    /// The word's own text driver — mirrors `isPublic` on ordinary taps but stays frozen on the
    /// retiring tap, so the numericText roll doesn't fire on a word that is fading out.
    @State private var wordIsPublic = true
    /// Phase A of retirement: the word fades/blurs out IN PLACE (still occupies layout width).
    @State private var labelVisible = true

    /// The label rides along for the first few taps, then retires for good — after the 4th
    /// tap only the eyes icon remains (it keeps toggling).
    private var labelShown: Bool { tapCount < 4 }

    @ViewBuilder
    var body: some View {
        if bare {
            core
        } else {
            core.ghostSurface(Capsule())
        }
    }

    private var core: some View {
        HStack(spacing: R.pillGap) {
            Button {
                if tapCount == 3 {
                    // Retiring tap: ONE transaction — the eyes crossfade, the word's quick
                    // blur-out, its width collapse and the padding re-inset all start together
                    // (a delayed collapse read as laggy feedback). The word stays MOUNTED for
                    // the whole ride (no removal copy → nothing can fly off or trail); it just
                    // fades faster than the shared spring and rides the collapsing edge.
                    withAnimation(MorphChoreo.placeholderSwap) {
                        isPublic.toggle()
                        labelVisible = false
                    } completion: {
                        tapCount += 1   // unmount only — already 0-wide and invisible
                    }
                } else {
                    withAnimation(MorphChoreo.placeholderSwap) {
                        isPublic.toggle()
                        wordIsPublic.toggle()
                        tapCount += 1
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    if labelShown {
                        // nil → 0 width animates as layout in the retiring transaction;
                        // .leading = the word rides the collapsing edge (constant inset to it).
                        PublicityWord(isPublic: wordIsPublic, visible: labelVisible)
                            .frame(width: labelVisible ? nil : 0, alignment: .leading)
                    }
                    PublicityEyes(isPublic: isPublic)
                }
            }
            // Composite button → publish the press, don't scale the whole label: the word + eyes
            // scale themselves IN PLACE (own-centre) so nothing slides as the word swaps width or
            // retires. A whole-label `.center` scale dragged the off-centre eyes sideways.
            .buttonStyle(ContentPressStyle())

            Capsule()
                .fill(NumoColor.grayAlmost)
                .frame(width: R.pillDividerSize.width, height: R.pillDividerSize.height)
            iconBox("tag")
            if let tag {
                Text(tag)
                    .font(NumoFont.bodyWide16)
                    .foregroundStyle(NumoColor.neutralDark)
                    .fixedSize()                        // ideal width; no wrap mid-appear
                    .padding(.bottom, 4)                // optical lift, same as PublicityWord
                    .padding(.leading, R.pillLabelOverlap) // tuck toward the 🏷 box like word → eyes
                    .transition(.blurReplace)
            }
        }
        // `pillPadLeading` is tuned for the text label's lead-in; once the label retires, use
        // `pillPadRetired` so the lone eyes' left inset matches the tag's right inset (the wider
        // eyes glyph would otherwise read left-tight). Right-anchored pill → tucks in from the left.
        // Driven by `labelVisible` (not `labelShown`) so the re-inset animates WITH the word's
        // fade + width collapse, not after it — one motion, no laggy second phase.
        .padding(.leading, labelVisible ? R.pillPadLeading : R.pillPadRetired)
        // With a tag label outboard of the 🏷 icon the trailing inset is a text lead-out,
        // mirroring `pillPadLeading`; icon-only keeps the tight icon inset.
        .padding(.trailing, tag == nil ? R.pillPadTrailing : R.pillTagPadTrailing)
        .frame(height: R.pillHeight)
        // The tag label keeps its ideal width (`fixedSize`) while the capsule's width is
        // still mid-spring — crop the overhang so the appearing word never pokes past the
        // group's edge. Clip bounds == the glass capsule (the surface sizes to this core).
        .clipShape(Capsule())
    }

    private func iconBox(_ name: String) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: R.pillIcon, height: R.pillIcon)
            .foregroundStyle(NumoColor.neutralDark)
            .frame(width: R.pillIconBox, height: R.pillHeight)
    }
}

/// Press scale shared by the pill's two tappable children — mirrors `PressFadeStyle`'s feel.
private enum PublicityPress {
    static let scale: CGFloat = 0.96
    static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.66)
}

/// Word swap tuning. The roll spring is the numericText donor (NumericTextHostView / the
/// When-picker values); the blur is the word's retirement fade-out.
private enum PublicityWordSwap {
    static let roll: Animation = .spring(response: 0.4, dampingFraction: 0.6)
    static let retireBlur: CGFloat = 6
    /// Quicker than the shared collapse spring: the word is gone before it slides far,
    /// so the fade reads as instant feedback and never overlaps the eyes box.
    static let retireFade: Animation = .easeOut(duration: 0.18)
}

/// The "Public"/"Private" word — ONE stable `Text` whose glyphs roll in place via the native
/// numericText transition (the When-picker recipe): no inserted/removed word copies, so the
/// width delta interpolates as smooth layout instead of a lateral slide. Scales IN PLACE on
/// press (own centre). On retirement it fades/blurs out where it stands (`visible`), with its
/// text frozen by the caller so the roll doesn't fire mid-disappearance.
private struct PublicityWord: View {
    let isPublic: Bool
    let visible: Bool
    @Environment(\.contentPressed) private var pressed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(isPublic ? "Public" : "Private")
            .font(NumoFont.bodyWide16)
            .foregroundStyle(NumoColor.neutralDark)
            .fixedSize()                            // single-line ideal width; no wrap mid-swap
            .contentTransition(reduceMotion ? .opacity : .numericText())
            .animation(PublicityWordSwap.roll, value: isPublic)
            .opacity(visible ? 1 : 0)
            .blur(radius: visible ? 0 : PublicityWordSwap.retireBlur)
            .animation(PublicityWordSwap.retireFade, value: visible)
            .padding(.bottom, 4)                    // optical lift (Figma label box pb 4)
            .padding(.trailing, R.pillLabelOverlap)
            .scaleEffect(pressed ? PublicityPress.scale : 1)       // own-centre shrink → no slide
            .animation(PublicityPress.spring, value: pressed)
    }
}

/// Eyes glyph: open (Public) ↔ crossed (Private). Both glyphs are ALWAYS mounted and cross-fade
/// via opacity+blur in the fixed 48-box — same look as `.blurReplace`, but with no view
/// insertion/removal there is never an outgoing copy that can fly off or leave a trail when the
/// word retires and the layout collapses around it. Scales IN PLACE on press (own centre).
private struct PublicityEyes: View {
    let isPublic: Bool
    @Environment(\.contentPressed) private var pressed

    private static let swapBlur: CGFloat = 6

    var body: some View {
        ZStack {
            glyph("eyes")
                .opacity(isPublic ? 1 : 0)
                .blur(radius: isPublic ? 0 : Self.swapBlur)
            glyph("eyes_crossed")
                .opacity(isPublic ? 0 : 1)
                .blur(radius: isPublic ? Self.swapBlur : 0)
        }
        .frame(width: R.pillIconBox, height: R.pillHeight)
        .scaleEffect(pressed ? PublicityPress.scale : 1)           // own-centre shrink → no slide
        .animation(PublicityPress.spring, value: pressed)
    }

    private func glyph(_ name: String) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: R.pillIcon, height: R.pillIcon)
            .foregroundStyle(NumoColor.neutralDark)
    }
}
