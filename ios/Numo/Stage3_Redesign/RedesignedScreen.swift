import GlassTabBar
import SwiftUI

private typealias R = Metrics.Redesign

/// UILabel wrapper for the redesign placeholder — exact 46pt line height + kern
/// (SwiftUI `Text` can't tighten ObviouslyNarrow-Bold's loose leading; same trick as
/// `ConsoleCard`'s placeholder and the Stage 2 overlay title).
private struct RedesignPlaceholder: UIViewRepresentable {
    var text: String
    var tracking: CGFloat

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        apply(to: label)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        apply(to: uiView)
    }

    private func apply(to label: UILabel) {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = R.inputLineHeight
        style.maximumLineHeight = R.inputLineHeight
        let font = UIFont(name: "ObviouslyNarrow-Bold", size: 40) ?? UIFont.systemFont(ofSize: 40)
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: UIColor(NumoColor.grayNormal),
                .kern: tracking,
                .paragraphStyle: style
            ]
        )
    }
}

/// Stage 3 — the redesigned task-entry screen (Figma 1128:14564).
/// Figma painterly artwork (`redesign_bg`) full-bleed behind a white canvas; header
/// (close + publicity/tags pill), natural-language input with the real keyboard, bottom
/// bar riding it.
///
/// Two entry modes:
/// - `viaMorph` (the "See how" release): the old screen has already raised a full white
///   cover, so this mounts already covered (`coverPhase == .cover`) and simply retracts
///   the canvas to the resting sheet — revealing the Figma background. Then the chrome +
///   bottom bounce in; a beat later the placeholder blur-swaps; then the keyboard opens.
/// - Cold boot (`NUMO_START=redesign` or replay): static resting state, immediate focus.
struct RedesignedScreen: View {
    /// How far the white canvas's top edge sits from y=0, and its corner radius.
    private enum CoverPhase {
        case belowScreen // parked off-screen below (direct slide-up open; whole screen is the bg)
        case start   // reconstructed stretched console (top at the old console's position)
        case cover   // full-screen white (top at y=0)
        case rest    // resting sheet (top below the status bar)
    }

    var morph: Namespace.ID? = nil
    var viaMorph: Bool = false
    /// Direct open from "+": the canvas slides up from the bottom, covers, then retracts to
    /// reveal the Figma bg (see `runSlideUpTimeline`). Mutually exclusive with `viaMorph`.
    var viaSlideUp: Bool = false

    @EnvironmentObject private var flow: AppFlowCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var text = ""
    @FocusState private var inputFocused: Bool

    // Liquid Glass chrome — the ✕/Clear/Confirm/publicity buttons are the same
    // GlassButton component the toolbar uses (each owns its own press feedback).
    // Injected config so the RN dev panel's shadow slider drives it too;
    // `chromeMorphing` is the shared picker-swap decor hide passed to each.
    @Environment(\.numoGlass) private var glass
    @State private var chromeMorphing = false
    @State private var chromeMorphToken = 0

    // Stage 41: RN owns the bottom-bar cluster. `rnBridge.rnBottomBar` removes
    // the native cluster (RN renders its own above the overlay); the RN-owned
    // picker state mirrors in via `rnBridge.whenPickerOpen` (drives the header
    // swap + backdrop on the SAME native springs), and picker intents flow
    // back out through `emit` (clearWhen/confirmWhen/backdropTap + entry/exit
    // beats) instead of mutating local state.
    @EnvironmentObject private var rnBridge: NumoFlowPropsBridge
    @Environment(\.numoFlowEmit) private var emit

    @State private var closing = false       // guards the close-down (direct overlay)
    @State private var closeY: CGFloat = 0   // canvas's downward translate during the close
    @State private var bgHidden = false      // fades the Figma bg image to opacity 0 on close

    // "When" picker — a mode of this screen. Toggling `whenPickerOpen` morphs the bottom bar
    // (and the chrome/voice/backdrop that read it) between the chip card and the picker on one
    // fluid open/close spring (see PickerMorph / openWhenPicker).
    @State private var whenPickerOpen: Bool
    /// Picker CONTENT visibility — decoupled from `whenPickerOpen` (the geometry) so that on
    /// close the content can fade out fast (ahead of the shell collapse). Open: rides the open
    /// spring with the shell; close: leads out on `PickerMorph.contentFadeOut`.
    @State private var pickerContentShown: Bool
    /// Natural height of the open picker — measured (deterministic now the wheel is fixed-height).
    /// The shell animates its frame between this and the chip height, so the grow is a smooth
    /// interpolation between two KNOWN values (a height driven by content insertion can't animate).
    @State private var pickerHeight: CGFloat = 0
    @State private var whenSection: WhenSection           // opens on the time wheel by default
    @State private var selectedDay: Date? = nil           // nil ⇒ today
    @State private var selectedTime: Date = Date()

    // Morph state — initialized to the resting/final values unless arriving via the
    // morph, so the first frame is correct in both entry modes (no pop-in).
    @State private var coverPhase: CoverPhase
    @State private var bgFigma: Bool          // false = blue + banner (matches the old screen) during the flight
    @State private var ghostOut: Bool         // old back/Public header flies out during the rise
    @State private var newChromeIn: Bool
    @State private var bottomBarIn: Bool
    @State private var showsNewPlaceholder: Bool

    private static let oldPlaceholderCopy = "Brain dump your\ntasks\u{2026}"
    private static let newPlaceholderCopy = "Type naturally: e.g.\n\"meds 9am daily\""
    /// Peak blur (pt) as the header chrome cross-fades ✕/publicity ⇄ Clear·When·✓.
    private static let headerBlur: CGFloat = 8

    init(morph: Namespace.ID? = nil, viaMorph: Bool = false, viaSlideUp: Bool = false) {
        self.morph = morph
        self.viaMorph = viaMorph
        self.viaSlideUp = viaSlideUp
        if viaSlideUp {
            // Park the canvas off-screen below over a WHITE bg (Figma unseen); the timeline
            // rises to touch the top, sets the Figma bg under cover, then drops to rest with a
            // bounce — revealing it. Chrome/bottom land on the drop; keyboard rises at the start.
            _coverPhase = State(initialValue: .belowScreen)
            _bgFigma = State(initialValue: false)
            _ghostOut = State(initialValue: true)
            _newChromeIn = State(initialValue: false)
            _bottomBarIn = State(initialValue: false)
            _showsNewPlaceholder = State(initialValue: true)
        } else {
            _coverPhase = State(initialValue: viaMorph ? .start : .rest)
            _bgFigma = State(initialValue: !viaMorph)
            _ghostOut = State(initialValue: !viaMorph)
            _newChromeIn = State(initialValue: !viaMorph)
            _bottomBarIn = State(initialValue: !viaMorph)
            _showsNewPlaceholder = State(initialValue: !viaMorph)
        }

        // Debug: NUMO_WHEN=time|date boots straight into the open "When" picker (cold boot
        // only) for headless screenshots; NUMO_WHEN=anim boots closed then auto-plays the
        // open/close morph (for headless video capture) — mirrors NUMO_START / NUMO_SCROLL.
        let whenEnv = ProcessInfo.processInfo.environment["NUMO_WHEN"]
        let bootsOpen = !viaMorph && !viaSlideUp && (whenEnv == "time" || whenEnv == "date")
        _whenPickerOpen = State(initialValue: bootsOpen)
        _pickerContentShown = State(initialValue: bootsOpen)
        _whenSection = State(initialValue: whenEnv == "date" ? .date : .time)
    }

    /// The stretched console's top edge, measured from the screen top — derived from the
    /// same Stage-1 metrics so the reconstruction lands exactly on it (no swap jump):
    /// safe area + the banner's laid-out height (banner − overlap) + the card margin + the
    /// draw-down pull.
    private func consoleTop(_ safeTop: CGFloat) -> CGFloat {
        safeTop + (Metrics.bannerHeight - Metrics.bannerOverlap)
            + Metrics.cardTopMargin + MorphChoreo.consolePull
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            // Full SCREEN size, independent of the bottom safe-area inset: when the picker
            // grows the inset, `geo.size.height` shrinks by exactly that growth while
            // `safeAreaInsets.bottom` grows by it, so this sum is constant. Sizing the canvas
            // off it (not off `geo.size`) keeps the background pinned while the picker opens.
            let screenSize = CGSize(width: geo.size.width,
                                    height: geo.size.height + safeTop + geo.safeAreaInsets.bottom)
            // The canvas-pin full-screen height doubles as the close drop distance (clears the
            // screen even with the keyboard up, since the insets are added back in).
            ZStack(alignment: .top) {
                background(safeTop: safeTop, screenSize: screenSize)
                sheet(safeTop: safeTop, height: geo.size.height, dropHeight: screenSize.height)
            }
            .ignoresSafeArea()   // full-bleed canvas; we inset the white's top via `safeTop`
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // RN-owned cluster: no native bar, no bottom inset — the RN sibling
            // rides the keyboard itself.
            if !rnBridge.rnBottomBar { bottomBar }
        }
        // Mirror the RN-owned picker state onto the native springs so the
        // header swap/backdrop run the exact same choreography as before.
        .onChange(of: rnBridge.whenPickerOpen) { _, open in
            guard rnBridge.rnBottomBar, open != whenPickerOpen else { return }
            if open {
                withAnimation(PickerMorph.openSpring) { whenPickerOpen = true; pickerContentShown = true }
            } else {
                withAnimation(PickerMorph.contentFadeOut) { pickerContentShown = false }
                withAnimation(PickerMorph.closeSpring) { whenPickerOpen = false }
            }
        }
        // Hidden debug trigger (as on Stage 1): triple-tap cycles the stage.
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture(count: 3).onEnded { flow.debugAdvance() })
        .onAppear {
            if viaSlideUp {
                runSlideUpTimeline()
            } else if viaMorph {
                runReleaseTimeline()
            } else {
                // Defer one runloop so focus (and the keyboard) engages reliably.
                DispatchQueue.main.async { inputFocused = true }
                // Debug: auto-play the open→close morph for headless video capture.
                if ProcessInfo.processInfo.environment["NUMO_WHEN"] == "anim" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { openWhenPicker() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) { closeWhenPicker() }
                }
            }
        }
        // Cold launch races scene activation: focusing while the scene is still
        // inactive shows no keyboard (sometimes not even the caret). Re-engage the
        // focus once the scene is actually active (not during a morph landing).
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, flow.morphPhase == .idle else { return }
            inputFocused = false
            DispatchQueue.main.async { inputFocused = true }
        }
    }

    /// Acts II (the reconstructed console flies up to full cover, then retracts back to its
    /// resting position) + III (the button groups, then text+keyboard, launch off the
    /// canvas's landing — follow-through inertia). See `MorphChoreo`.
    private func runReleaseTimeline() {
        // II: fly up from `.start` to full cover (explicit → always animates), old header
        // flying out; swap the bg blue+banner→Figma under cover; then retract to reveal it.
        let retractDelay = MorphChoreo.riseDur + MorphChoreo.coverHold
        withAnimation(MorphChoreo.riseSpring) { coverPhase = .cover }
        withAnimation(MorphChoreo.riseSpring) { ghostOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + MorphChoreo.riseDur) { bgFigma = true }
        withAnimation(MorphChoreo.retractSpring.delay(retractDelay)) { coverPhase = .rest }

        // III: the buttons launch during the retract's settle (a touch BEFORE it fully
        // lands), so they overlap and trail the canvas's drop. Then text+keyboard.
        let buttonsDelay = retractDelay + MorphChoreo.buttonsLead
        withAnimation(MorphChoreo.newHeaderSpring.delay(buttonsDelay)) { newChromeIn = true }   // drops in downward, with the canvas
        withAnimation(MorphChoreo.bottomBarSpring.delay(buttonsDelay + MorphChoreo.buttonsStagger)) { bottomBarIn = true }
        // RN-owned cluster plays its entry rise on the exact same beat.
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonsDelay + MorphChoreo.buttonsStagger) { [emit] in
            emit("barEnterMorph")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonsDelay + MorphChoreo.textAfterButtons) {
            withAnimation(MorphChoreo.placeholderSwap) { showsNewPlaceholder = true }
            inputFocused = true
            flow.morphPhase = .idle
        }
    }

    /// Direct open from "+": fast. The WHITE canvas rises to just touch the top edge (bg
    /// unseen), the Figma bg is set behind the full cover, then the canvas immediately drops
    /// back to rest with a bounce — revealing the bg for the first time. Chrome + bottom land
    /// on the drop; the keyboard rises at the very start, alongside the canvas. See
    /// `MorphChoreo` (slide-up knobs).
    private func runSlideUpTimeline() {
        inputFocused = true   // keyboard rises with the canvas
        let downDelay = MorphChoreo.slideRiseDur + MorphChoreo.slideCoverHold
        withAnimation(MorphChoreo.slideRiseSpring) { coverPhase = .cover }                             // rise over home → touch the top
        DispatchQueue.main.asyncAfter(deadline: .now() + MorphChoreo.slideRiseDur) { bgFigma = true }  // set the bg under full cover (home hidden)
        withAnimation(MorphChoreo.slideRetractSpring.delay(downDelay)) { coverPhase = .rest }          // straight down with a bounce → reveals the bg
        // Chrome lands after the bg is revealed; the bottom group launches early so it rides
        // up with the keyboard's inertia (same animation, just earlier).
        let chromeDelay = downDelay + MorphChoreo.slideButtonsLead
        withAnimation(MorphChoreo.newHeaderSpring.delay(chromeDelay)) { newChromeIn = true }
        withAnimation(MorphChoreo.bottomBarSpring.delay(MorphChoreo.slideBottomBarDelay)) { bottomBarIn = true }
        // RN-owned cluster plays its entry rise on the exact same beat.
        DispatchQueue.main.asyncAfter(deadline: .now() + MorphChoreo.slideBottomBarDelay) { [emit] in
            emit("barEnterSlide")
        }
    }

    /// Direct close — canvas-led downward slide: the canvas stretches up a hair (anticipation)
    /// then drops straight off the bottom; the bg image fades to opacity 0 (revealing home); the
    /// chrome AND bottom group are cropped by the descending canvas edge. The keyboard dismisses
    /// at the SAME time as the canvas. See `MorphChoreo`.
    private func runSlideDownTimeline(height: CGFloat) {
        guard !closing else { return }
        closing = true
        emit("closing")                        // RN-owned cluster fades out with the bottom group
        inputFocused = false                   // keyboard dismisses NOW — simultaneous with the canvas
        withAnimation(MorphChoreo.slideCloseBottomFade) { bottomBarIn = false }                         // bottom group fades out fast as it goes
        withAnimation(MorphChoreo.slideCloseStretchSpring) { closeY = -MorphChoreo.slideCloseStretch }  // stretch up (anticipation)
        withAnimation(MorphChoreo.slideCloseBgFade) { bgHidden = true }                                 // image → opacity 0 (reveals home)
        DispatchQueue.main.asyncAfter(deadline: .now() + MorphChoreo.slideCloseStretchDur) {
            withAnimation(MorphChoreo.slideCloseDropSpring) { closeY = height }                          // slide down off the bottom
        }
        let total = MorphChoreo.slideCloseStretchDur + MorphChoreo.slideCloseDropDur
        DispatchQueue.main.asyncAfter(deadline: .now() + total) { flow.directOpen = false }              // remove the off-screen overlay → home
    }

    /// During the flight: blue + the reconstructed AI-voice banner at the top (matches the
    /// old screen exactly, so the banner doesn't vanish — the rising sheet covers it). Once
    /// covered, swap to the Figma painting, which the retract then reveals.
    private func background(safeTop: CGFloat, screenSize: CGSize) -> some View {
        Group {
            if bgFigma {
                Image("redesign_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
                    .clipped()
                    .opacity(bgHidden ? 0 : 1)   // fades to reveal home on the slide-down close
            } else if viaSlideUp {
                // Slide-up: transparent so HOME shows through the rising sheet (bottom-sheet
                // cover). The Figma bg is set under full cover (home hidden), then revealed on the drop.
                Color.clear
            } else {
                ZStack(alignment: .top) {
                    NumoColor.vibrant
                    VoiceBanner()
                        .padding(.top, safeTop + MorphChoreo.consolePull)
                }
            }
        }
        // Pinned to the full screen, top-anchored — growing the bottom picker inset never
        // resizes or shifts the canvas.
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
        .ignoresSafeArea()
    }

    private func topInset(_ safeTop: CGFloat, _ height: CGFloat) -> CGFloat {
        switch coverPhase {
        case .belowScreen: return height   // parked off-screen below (whole screen is the bg)
        case .start: return consoleTop(safeTop)
        case .cover: return 0
        case .rest:  return safeTop
        }
    }

    /// The white canvas + content — the destination the console flies into (matched
    /// `.console`). Resting: top at `safeTop` (Figma artwork shows in the status-bar strip),
    /// rounded corners, full-bleed to the bottom INCLUDING behind the keyboard. On release it
    /// mounts at full cover (top y=0) and retracts to rest.
    private func sheet(safeTop: CGFloat, height: CGFloat, dropHeight: CGFloat) -> some View {
        let inset = topInset(safeTop, height)
        // Keep the console's rounding (36) through the flight; only the resting sheet is 48.
        let radius: CGFloat = coverPhase == .rest ? R.sheetTopRadius : Metrics.cardRadius

        return VStack(spacing: 0) {
            // Top chrome — Liquid Glass slots (the toolbar's lead/trail mechanic):
            // the ✕ ghost morphs into the picker's Clear pill and the publicity
            // group into the accent ✓ via matched glassEffectIDs. The old manual
            // blur+opacity cross-fade is gone — the glass morph IS the transition.
            ZStack {
                // Centered "When" title — non-glass content, the donor's
                // blur+opacity swap: eases in with the picker, leaves FAST.
                Text("When")
                    .font(NumoFont.obviouslyNarrowBold(R.WhenPicker.titleSize))
                    .tracking(R.WhenPicker.titleTracking)
                    .foregroundStyle(NumoColor.black)
                    .opacity(whenPickerOpen ? 1 : 0)
                    .blur(radius: whenPickerOpen ? 0 : Self.headerBlur)
                    .animation(
                        whenPickerOpen ? MorphChoreo.placeholderSwap : .easeOut(duration: 0.18),
                        value: whenPickerOpen)

                // The picker header swap is the DONOR's cross-fade: both clusters
                // are always laid out in the same slot and swap via blur+opacity
                // (like the "When" title) — no matched glass morph. The whole
                // block ENTERS with the donor's opacity+offset drop (newChromeIn),
                // exactly as it did on the first merge — no materialize.
                // No GlassEffectContainer: it aggregates every glassEffect into
                // one render layer, so a descendant .opacity can't fade the glass.
                ZStack {
                    // CLOSED — ✕ + publicity/tags; blurs out in place.
                    HStack {
                        glassCloseButton(dropHeight: dropHeight)
                        Spacer(minLength: 0)
                        glassPublicityGroup
                    }
                    .opacity(whenPickerOpen ? 0 : 1)
                    .blur(radius: whenPickerOpen ? Self.headerBlur : 0)
                    .allowsHitTesting(!whenPickerOpen)

                    // OPEN — Clear · ✓; blurs in at its final positions.
                    HStack {
                        glassClearButton
                        Spacer(minLength: 0)
                        glassConfirmButton
                    }
                    .opacity(whenPickerOpen ? 1 : 0)
                    .blur(radius: whenPickerOpen ? 0 : Self.headerBlur)
                    .allowsHitTesting(whenPickerOpen)
                }
                .animation(MorphChoreo.placeholderSwap, value: whenPickerOpen)
                .padding(.horizontal, R.WhenPicker.headerPadH)
                .padding(.vertical, R.WhenPicker.headerPadV)
            }
            .opacity(newChromeIn ? 1 : 0)
            // Enter with the donor's drop, and counter the sheet's close-translate
            // so the chrome stays screen-pinned and is cropped (not moved) by the
            // sheet's descending top edge as the canvas slides down.
            .offset(y: (newChromeIn ? 0 : MorphChoreo.newHeaderDrop) - closeY)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            RedesignPlaceholder(
                                text: showsNewPlaceholder ? Self.newPlaceholderCopy : Self.oldPlaceholderCopy,
                                tracking: showsNewPlaceholder ? R.inputTracking : Metrics.inputTracking
                            )
                            .id(showsNewPlaceholder)
                            .transition(.blurReplace)
                        }
                        TextField("", text: $text, axis: .vertical)
                            .font(NumoFont.obviouslyNarrowBold(40))
                            .tracking(R.inputTracking)
                            .foregroundStyle(NumoColor.text)
                            .tint(NumoColor.highlight)
                            .focused($inputFocused)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, R.inputPadH)
                    // Frosted backdrop: the input reads as a soft, dimmed layer behind the open
                    // picker (Figma panel's backdrop-blur + white@60%). Reads `whenPickerOpen` so it
                    // animates on the same open/close spring as the shell.
                    .blur(radius: whenPickerOpen ? R.WhenPicker.backdropBlur : 0)
                    .overlay {
                        NumoColor.white
                            .opacity(whenPickerOpen ? R.WhenPicker.backdropDim : 0)
                            .allowsHitTesting(false)
                    }

                    Spacer(minLength: 0)
                }

                // Tap-outside-to-dismiss: while the picker is open, a transparent catcher over
                // the region below the header (the dimmed input + empty space — but not the
                // Clear/✓ header above it, nor the picker card in the bottom inset, which both
                // render on top) closes the picker. Never resigns the keyboard.
                if whenPickerOpen {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if rnBridge.rnBottomBar { emit("backdropTap") } else { closeWhenPicker() }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NumoColor.white)
        // Ghost old header (back + Public) reconstructs the stretched console's header so it
        // doesn't vanish at the swap; it flies up + fades during the rise, cropped by the
        // sheet's rounded top.
        .overlay(alignment: .top) {
            if viaMorph {
                HStack {
                    BackButton()
                    Spacer(minLength: 0)
                    PublicityPill(isPublic: true)
                }
                .padding(.horizontal, Metrics.headerInset)
                .padding(.top, Metrics.headerInset)
                .opacity(ghostOut ? 0 : 1)
                .offset(y: ghostOut ? -MorphChoreo.ghostRise : 0)
                .allowsHitTesting(false)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: radius, topTrailing: radius),
                style: .continuous
            )
        )
        .padding(.top, inset)   // positions the canvas top: start → 0 (cover) → safeTop (rest)
        .offset(y: closeY)      // close: canvas slides down off the bottom (stretch → drop)
    }

    // MARK: - "When" picker actions

    /// Open the picker (only in the resting/idle state — never mid-morph). ONE spring drives
    /// the whole fluid morph: every property that reads `whenPickerOpen` (shell size/radius,
    /// content, chrome, voice, backdrop) animates together in this single transaction.
    // MARK: - Liquid Glass chrome buttons (donor cross-fade, no matched morph)

    // The chrome buttons are the SAME GlassButton component the toolbar uses —
    // identical material, decor and press feedback. Only the font is ours
    // (Obviously); the toolbar CTA passes SF. `chromeMorphing` drives the
    // picker-swap decor hide.
    private func glassCloseButton(dropHeight: CGFloat) -> some View {
        GlassButton(Circle(), config: glass, morphing: chromeMorphing,
                    interaction: .tap {
                        if viaSlideUp {
                            runSlideDownTimeline(height: dropHeight)
                        } else {
                            emit("closing")
                            flow.goHome()
                        }
                    }) {
            Image("cross")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.crossIcon, height: R.crossIcon)
                .foregroundStyle(NumoColor.grayNight)
                .frame(width: R.closeSize, height: R.closeSize)
        }
    }

    private var glassClearButton: some View {
        GlassButton(Capsule(), config: glass, morphing: chromeMorphing,
                    interaction: .tap {
                        if rnBridge.rnBottomBar { emit("clearWhen") }
                        else { clearWhenSelection(); closeWhenPicker() }
                    }) {
            Text("Clear")
                .font(NumoFont.obviouslySemibold(R.WhenPicker.clearLabel))
                .foregroundStyle(NumoColor.neutralDark)
                .padding(.bottom, R.WhenPicker.clearLabelLift)
                .frame(width: R.WhenPicker.clearWidth, height: R.WhenPicker.clearHeight)
        }
    }

    /// The publicity content keeps its own internal buttons (word/eyes
    /// blur-swap + in-place press scale), so the group carries no tap of its
    /// own — the `.group` interaction only hides the decor on a real drag.
    private var glassPublicityGroup: some View {
        GlassButton(Capsule(), kind: .group, config: glass, morphing: chromeMorphing,
                    interaction: .group) {
            PublicityTagsPill(bare: true)
        }
    }

    private var glassConfirmButton: some View {
        GlassButton(Capsule(), kind: .accent, config: glass, morphing: chromeMorphing,
                    interaction: .tap {
                        if rnBridge.rnBottomBar { emit("confirmWhen") } else { closeWhenPicker() }
                    }) {
            Image("picker_checkmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.WhenPicker.checkIcon, height: R.WhenPicker.checkIcon)
                .foregroundStyle(NumoColor.white)
                .frame(width: R.WhenPicker.clearWidth, height: R.WhenPicker.clearHeight)
        }
    }

    // Hides every slot's decor for the duration of a chrome morph. Called
    // SYNCHRONOUSLY BEFORE the state flip so the incoming slot's very first
    // frame is already decor-less (an onChange-driven hide runs after body —
    // the fresh slot's ring would flash on the target frame ahead of the
    // flying glass). The clear waits out the PickerMorph springs' settle
    // (response 0.40, damping 0.82/0.90 → ~0.5s) so the ring never returns
    // while the glass is still in flight.
    private func chromeMorphStarted(clearAfter: TimeInterval = 0.5) {
        chromeMorphing = true
        chromeMorphToken += 1
        let token = chromeMorphToken
        DispatchQueue.main.asyncAfter(deadline: .now() + clearAfter) {
            if chromeMorphToken == token {
                withAnimation(.easeInOut(duration: 0.3)) { chromeMorphing = false }
            }
        }
    }

    private func openWhenPicker() {
        guard flow.morphPhase == .idle, !whenPickerOpen else { return }
        withAnimation(PickerMorph.openSpring) { whenPickerOpen = true; pickerContentShown = true }
    }

    /// ✓ — confirm & close. The shell collapses on the close spring; the CONTENT leads out on a
    /// quicker fade so it's gone before the card finishes shrinking.
    private func closeWhenPicker() {
        guard whenPickerOpen else { return }
        withAnimation(PickerMorph.contentFadeOut) { pickerContentShown = false }
        withAnimation(PickerMorph.closeSpring) { whenPickerOpen = false }
    }

    /// Clear — reset the day + time but keep the picker open to re-pick.
    private func clearWhenSelection() {
        selectedDay = nil
        selectedTime = Date()
    }

    /// Routine/When card + voice button over a transparent→white gradient; rides the
    /// keyboard via the bottom safe-area inset. Bounces up from below as one unit.
    /// When the picker is open, the card is swapped for the `WhenPicker` in its place.
    private var bottomBar: some View {
        // ONE continuous ghost-surface shell that never inserts/removes — it MORPHS. The single
        // open/close spring animates EVERY property here together (one transaction, all reading
        // `whenPickerOpen`): the shell's explicit height between two KNOWN values (chip 82 ↔ the
        // measured picker height — the dominant motion, and the thing v1 failed to animate), its
        // width (trailing slot for the voice button closes), its radius (20→24), the chip/picker
        // cross-fade, and the voice fade. Both children are ALWAYS mounted (the heavy wheel never
        // instantiates mid-animation → no opening hitch); the picker just rides opacity + a subtle
        // bottom-anchored scale. The blue voice button is a sibling overlay shown only when closed.
        let radius: CGFloat = whenPickerOpen ? PickerMorph.radiusOpen : PickerMorph.radiusClosed
        let shellHeight = whenPickerOpen ? max(pickerHeight, R.cardHeight) : R.cardHeight
        return ZStack(alignment: .bottomTrailing) {
            // Voice CTA sits BEHIND the shell so the expanding picker renders on top and covers
            // it; it also fades out fast (chromeFadeOut) so it's gone before the picker arrives.
            VoiceButton(config: glass)
                .opacity(whenPickerOpen ? 0 : 1)
                .animation(PickerMorph.chromeFadeOut, value: whenPickerOpen)
                .allowsHitTesting(!whenPickerOpen)

            ZStack(alignment: .bottom) {   // bottom-anchored at the chip line
                RoutineTimeCard(onWhenTap: openWhenPicker, bare: true)
                    .opacity(whenPickerOpen ? 0 : 1)
                    .animation(PickerMorph.chromeFadeOut, value: whenPickerOpen)   // labels vanish fast
                    .allowsHitTesting(!whenPickerOpen)

                WhenPicker(section: $whenSection,
                           selectedDay: $selectedDay,
                           selectedTime: $selectedTime,
                           bare: true)
                    // Always mounted; measure its (now deterministic) natural height so the shell
                    // has a known target to grow into. Reads its true height in both states (it
                    // ignores the shell's clamp — content is fixed-size), so no first-open jump.
                    // While OPEN, a section swap (Date↔Time) changes the measured height — glide
                    // the shell frame to it on the SAME `sectionResize` spring as the content so
                    // they move as one (no snap/clip). Closed/boot measurement stays instant so
                    // the open/close grow keeps riding its own spring.
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
                        if whenPickerOpen { withAnimation(PickerMorph.sectionResize) { pickerHeight = h } }
                        else { pickerHeight = h }
                    }
                    // Grows up out of the chip line with the shell (rides the same spring); the
                    // CONTENT opacity is on its own flag so it can lead OUT fast on close.
                    .scaleEffect(whenPickerOpen ? 1 : PickerMorph.contentScaleFrom, anchor: .bottom)
                    .opacity(pickerContentShown ? 1 : 0)
                    .allowsHitTesting(whenPickerOpen)
            }
            .frame(maxWidth: .infinity)
            .frame(height: shellHeight, alignment: .bottom)   // explicit + known → smooth grow
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            // Same Liquid Glass material as the buttons (the container surface,
            // no gesture — the inner chips/wheel own their interactions).
            .glassSurface(RoundedRectangle(cornerRadius: radius, style: .continuous), config: glass)
            .padding(.trailing, whenPickerOpen ? 0 : R.voiceSize.width + R.barGap)
        }
        .padding(.horizontal, R.barPadH)
        .padding(.top, R.barPadTop)
        .padding(.bottom, R.barPadBottom)
        // Tap-outside-to-dismiss: a scrim behind the bar content (in front of the gradient).
        // Tapping the gradient padding around/above the picker card closes it; the card itself
        // (rows/wheel/white bg) is in front and consumes its own taps. Inert when closed.
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { closeWhenPicker() }
                .allowsHitTesting(whenPickerOpen)
        )
        .background(
            // Eased ramp approximating the Figma gradient (solid by ~27% of height).
            LinearGradient(
                stops: [
                    .init(color: NumoColor.white.opacity(0), location: 0),
                    .init(color: NumoColor.white.opacity(0.12), location: 0.095),
                    .init(color: NumoColor.white.opacity(0.50), location: 0.15),
                    .init(color: NumoColor.white.opacity(0.85), location: 0.21),
                    .init(color: NumoColor.white, location: R.barGradientSolidStop),
                    .init(color: NumoColor.white, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        // Slide-up: fade in from a short rise so the group appears near its resting spot (not
        // tracking the full keyboard height). Morph keeps its long drop.
        .opacity(viaSlideUp && !bottomBarIn ? 0 : 1)
        .offset(y: bottomBarIn ? 0 : (viaSlideUp ? MorphChoreo.slideBottomBarRise
                                                 : MorphChoreo.bottomBarRise))
    }
}
