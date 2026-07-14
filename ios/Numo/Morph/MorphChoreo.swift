import SwiftUI

/// Stage 1 → Stage 3 morph choreography — every timing/spring/offset in one place
/// (same pattern as `BrainDumpEntrance`). Three acts:
///   I   STRETCH — the drawn bow: overlay fades, the console swells DOWN to fill
///       center+bottom (pushing the sections off as a cohesive block), banner sticky.
///       Smooth, non-overshooting (it only goes up on release).
///   II  RELEASE — explicit cover: the white canvas flies UP to cover the full screen,
///       holds, then retracts — revealing the new (Figma) background behind it.
///   III LANDING — top chrome + bottom group bounce in; then, a beat later, the
///       placeholder blur-swaps; then the keyboard opens.
enum MorphChoreo {
    // ── Act I — stretch (the drawn bow: DOWN only, no rebound) ──
    /// How long the draw-down is held before the release fires.
    static let stretchDuration: TimeInterval = 1.5
    static let overlayFadeOut: TimeInterval = 0.18
    /// Smooth, non-overshooting draw-down — the form stretches down and holds; it only
    /// travels up on release. Used by banner + console (offset) and the console growth.
    static let drawDown: Animation = .spring(duration: 0.7, bounce: 0)
    /// Tension pull: banner + console drawn down a touch (down only).
    static let consolePull: CGFloat = 30
    /// The console grows by this much (inner bottom padding) — the growth alone pushes
    /// ALL sections down uniformly (pure layout), so they keep their spacing and exit
    /// the screen as one block. No per-section offsets.
    static let consoleGrowth: CGFloat = 700

    // ── Act II — the reconstructed console flies up to full cover, then retracts ──
    /// Where the reconstructed console's top sits at `.start` (≈ the stretched console's
    /// top), so the redesign's first frame lands exactly on it. Tune so there's no jump.
    static let coverStart: CGFloat = 250
    /// Snappy rise from `.start` (coverStart) to `.cover` (full screen) — the visible
    /// "release" motion; fast, to match the power of the slow 1.5s draw-down (bow release).
    static let riseSpring: Animation = .spring(duration: 0.38, bounce: 0.12)
    /// How long the flight takes before the bg swaps (blue+banner→Figma) under full cover.
    static let riseDur: TimeInterval = 0.38
    /// Old back/Public header flies this far up (cropped by the sheet) as the console rises.
    static let ghostRise: CGFloat = 120
    /// Hold full white a beat after the flight, then retract to reveal the Figma background.
    static let coverHold: TimeInterval = 0.20
    static let retractSpring: Animation = .spring(duration: 0.6, bounce: 0.18)

    // ── Act III — landing (launched off the retract's COMPLETION, i.e. the moment the
    //    canvas is back at its resting position — the buttons follow its drop inertia) ──
    /// Top chrome + bottom group appear with a visible bounce.
    static let newHeaderSpring: Animation = .spring(duration: 0.5, bounce: 0.40)
    static let newHeaderDrop: CGFloat = -28
    static let bottomBarSpring: Animation = .spring(duration: 0.55, bounce: 0.22)
    static let bottomBarRise: CGFloat = 280
    /// When the buttons launch, measured from the retract START. The retract settles in
    /// ~`retractSpring` duration (~0.6); this is a bit less, so the buttons begin during
    /// the retract's final settle and trail the canvas's drop rather than waiting for it
    /// to fully land.
    static let buttonsLead: TimeInterval = 0.30
    /// Upper chrome leads the lower group by a hair.
    static let buttonsStagger: TimeInterval = 0.06
    /// After the buttons launch, the placeholder blur-swap + keyboard fire together once
    /// they've settled.
    static let textAfterButtons: TimeInterval = 0.45
    static let placeholderSwap: Animation = .smooth(duration: 0.45)

    // ── Direct "+" open/close — the bottom-sheet slide-up / canvas-led slide-down (the
    //    redesign opens directly from home once onboarding has been seen). Separate, faster
    //    timeline from the Stage1→3 morph above; reuses newHeaderSpring/bottomBarSpring. ──
    /// OPEN: rise from below to full cover (quick, no overshoot), then drop to rest with a bounce.
    static let slideRiseSpring: Animation = .spring(duration: 0.18, bounce: 0.0)
    static let slideRiseDur: TimeInterval = 0.18
    static let slideCoverHold: TimeInterval = 0.0
    static let slideRetractSpring: Animation = .spring(duration: 0.32, bounce: 0.34)
    static let slideButtonsLead: TimeInterval = 0.10
    static let slideBottomBarRise: CGFloat = 40        // bottom group enters from a short rise (not full keyboard height)
    static let slideBottomBarDelay: TimeInterval = 0.06
    /// CLOSE: anticipation stretch UP, then the canvas drops straight off the bottom (full height).
    static let slideCloseStretch: CGFloat = 24
    static let slideCloseStretchSpring: Animation = .spring(duration: 0.10, bounce: 0.2)
    static let slideCloseStretchDur: TimeInterval = 0.10
    static let slideCloseDropSpring: Animation = .spring(duration: 0.32, bounce: 0)
    static let slideCloseDropDur: TimeInterval = 0.32
    static let slideCloseBgFade: Animation = .easeOut(duration: 0.18)   // bg fades faster than the drop → reveals home early
    static let slideCloseBottomFade: Animation = .easeOut(duration: 0.12)
}

/// Shared fluid morph for any bottom-bar picker (When, Routine, …): ONE continuous
/// `.ghostSurface` shell grows from the chip card into the picker. Every morphing property
/// reads the open flag and animates in a single `withAnimation` transaction, so size, radius,
/// content, chrome and backdrop all land together — the iOS-26 Liquid-Glass "contextual menu"
/// fluidity, on our flat surface. Pure glide: gentle elastic settle, no squash, no timers
/// (timers aren't velocity-aware → they kill interruptibility).
enum PickerMorph {
    static let radiusClosed: CGFloat = 20            // chip-card radius
    static let radiusOpen: CGFloat = 24              // picker-card radius

    /// Open — smooth grow with a soft settle; damping ~0.82 = the iOS system feel (a hair of
    /// overshoot, no bounce). Response kept short so the grow reads quick.
    static let openSpring: Animation = .spring(response: 0.40, dampingFraction: 0.82)
    /// Close — a touch faster + flatter so it reads crisp/final (minimal overshoot).
    static let closeSpring: Animation = .spring(response: 0.40, dampingFraction: 0.90)

    /// Chip labels + the blue CTA disappear on THIS quick fade (not the open spring) so they're
    /// gone fast — the picker grows up over where they were, on top.
    static let chromeFadeOut: Animation = .easeOut(duration: 0.12)

    /// On CLOSE the picker CONTENT fades out on this quick ease (ahead of the shell collapse) so
    /// it's gone before the card finishes shrinking. Open keeps the content on the open spring.
    static let contentFadeOut: Animation = .easeOut(duration: 0.12)

    /// Picker content scales up from the chip line as the shell grows. Subtle (≈0.96) — the
    /// explicit height grow is now the main motion; this just keeps the content from feeling
    /// detached. Reads as "the same surface stretching open."
    static let contentScaleFrom: CGFloat = 0.96

    /// Date↔Time accordion swap — clean inline-expand spring (no bounce), per the WWDC
    /// "animate with springs" guidance; interruptible so rapid row taps blend. The card frame
    /// and the content reposition/reveal ride this ONE spring so nothing leads or snaps.
    static let sectionResize: Animation = .smooth(duration: 0.3)

    /// The DISAPPEARING section's blur-out only — quicker than `sectionResize` so the defocused
    /// content clears before the eye records it (the appear stays on `sectionResize`).
    static let sectionDisappear: Animation = .easeOut(duration: 0.16)
}
