import SwiftUI

/// 1:1 port of the brain-dump form's mount/"appear" animation from the RN app
/// (`../RN Codebase/src/features/tasks/taskHook.tsx` + `TaskForm.tsx`).
///
/// RN behavior, exactly: 250 ms after the screen mounts, every block springs from a
/// downward `translateY` offset to 0 — **all blocks release simultaneously** (`Animated.parallel`).
/// The cascade look comes purely from the different offsets (lower sections start farther
/// down and so travel longer), NOT from staggered delays. The RN code also computes a
/// `scale 0.9→1`, but it is applied as a second `transform` key that the per-block
/// `{transform:[translateY]}` overrides — so it never renders. Faithful copy = translateY only.
///
/// Spring: RN `Animated.spring({ speed: 15.5, bounciness: 10 })` → (RN POP/Origami
/// `fromBouncinessAndSpeed`) analytic spring mass 1, stiffness ≈ 416.5, damping ≈ 24.3
/// (ζ ≈ 0.595, ωₙ ≈ 20.4 rad/s) → SwiftUI `.spring(response: 0.308, dampingFraction: 0.595)`.
enum BrainDumpEntrance {
    /// No pre-delay: we open the brain dump instantly, so the slide-up begins the moment
    /// the screen appears (tap → motion, no pause). RN's 250 ms masked a nav transition we
    /// don't have. The `.onAppear` still defers one runloop so the offset state renders
    /// first and the spring actually animates (rather than snapping to rest).
    static let delay: TimeInterval = 0
    static let spring: Animation = .spring(response: 0.308, dampingFraction: 0.595)

    /// When the Stage 2 overlay begins revealing, measured from the start of the entrance.
    /// Tuned to overlap the tail of the slide-up (the spring's `response` is ~0.31s) so the
    /// overlay flows continuously out of the entrance instead of waiting for the bouncy
    /// spring to fully settle (which read as a ~1s postponed gap).
    static let overlayRevealDelay: TimeInterval = 0.12
    /// Duration of the overlay's fade-in. Quick snap so the overlay is fully in very early
    /// (reveal 0.05 + fade 0.15 ≈ 0.2s, i.e. ~200ms after the brain dump opens).
    static let overlayFade: TimeInterval = 0.3

    // Per-section slide-up offsets (pt), 1:1 with the RN `blocksTransformValues` wiring.
    static let banner:   CGFloat = 30   // TasksVoiceBrainDumpBanner → console
    static let console:  CGFloat = 30   // TaskConsole              → console
    static let subtasks: CGFloat = 50   // TaskSubtasks             → subtasks
    static let settings: CGFloat = 70   // TaskDifficulty/TaskSettings → settings
    static let time:     CGFloat = 90   // TaskTime/Order/Tags/Notes → time
}

private struct EntranceSlide: ViewModifier {
    let offset: CGFloat
    let active: Bool
    func body(content: Content) -> some View {
        // `.offset` (not layout padding) mirrors the RN `transform: translateY` —
        // a render-time shift that doesn't reflow neighbors.
        content.offset(y: active ? 0 : offset)
    }
}

extension View {
    /// Slide this section up from `offset` to rest when `active` flips true
    /// (drive `active` inside `withAnimation(BrainDumpEntrance.spring)`).
    func entranceSlide(_ offset: CGFloat, active: Bool) -> some View {
        modifier(EntranceSlide(offset: offset, active: active))
    }
}
