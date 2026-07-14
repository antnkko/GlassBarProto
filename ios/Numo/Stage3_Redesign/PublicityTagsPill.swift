import SwiftUI

private typealias R = Metrics.Redesign

/// "Public 👀 | 🏷" capsule — publicity selector + tags entry combined.
/// Redesign counterpart of Stage 1's `PublicityPill` (Figma 1070:1720).
struct PublicityTagsPill: View {
    /// Bare = content only, no ghost surface — the Liquid Glass chrome in
    /// `RedesignedScreen` owns the surface (material + stroke + shadow).
    var bare: Bool = false

    @State private var isPublic = true
    @State private var tapCount = 0

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
                withAnimation(MorphChoreo.placeholderSwap) {
                    isPublic.toggle()
                    tapCount += 1
                }
            } label: {
                HStack(spacing: 0) {
                    if labelShown {
                        PublicityWord(isPublic: isPublic)
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
        }
        // `pillPadLeading` is tuned for the text label's lead-in; once the label retires, use
        // `pillPadRetired` so the lone eyes' left inset matches the tag's right inset (the wider
        // eyes glyph would otherwise read left-tight). Right-anchored pill → tucks in from the left.
        .padding(.leading, labelShown ? R.pillPadLeading : R.pillPadRetired)
        .padding(.trailing, R.pillPadTrailing)
        .frame(height: R.pillHeight)
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

/// The "Public"/"Private" word — blur-swaps per word and scales IN PLACE on press (own centre,
/// no horizontal drift). Lives under the toggle's `ContentPressStyle`, reading its held state.
private struct PublicityWord: View {
    let isPublic: Bool
    @Environment(\.contentPressed) private var pressed

    var body: some View {
        Text(isPublic ? "Public" : "Private")
            .font(NumoFont.bodyWide16)
            .foregroundStyle(NumoColor.neutralDark)
            .fixedSize()                            // single-line ideal width; no wrap mid-swap
            .padding(.bottom, 4)                    // optical lift (Figma label box pb 4)
            .padding(.trailing, R.pillLabelOverlap)
            .scaleEffect(pressed ? PublicityPress.scale : 1)       // own-centre shrink → no slide
            .animation(PublicityPress.spring, value: pressed)
            .id(isPublic)                           // new identity per word → transition fires
            .transition(.blurReplace)               // native blur+opacity swap; then the final hide
    }
}

/// Eyes glyph: open (Public) ↔ crossed (Private). Blur-swaps in its fixed 48-box (so the swap
/// never shifts layout) and scales IN PLACE on press (own centre) — the fixed-box anchor is why
/// it no longer drifts/​flies when the word swaps width or retires.
private struct PublicityEyes: View {
    let isPublic: Bool
    @Environment(\.contentPressed) private var pressed

    var body: some View {
        Image(isPublic ? "eyes" : "eyes_crossed")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: R.pillIcon, height: R.pillIcon)
            .foregroundStyle(NumoColor.neutralDark)
            .frame(width: R.pillIconBox, height: R.pillHeight)
            .scaleEffect(pressed ? PublicityPress.scale : 1)       // own-centre shrink → no slide
            .animation(PublicityPress.spring, value: pressed)
            .id(isPublic)
            .transition(.blurReplace)
    }
}
