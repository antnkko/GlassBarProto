import SwiftUI

enum AppStage { case current, onboarding, redesigned }

/// Sub-axis of the Stage 1 → Stage 3 morph (see `MorphChoreo`): `.stretching` draws the
/// form down on Stage 1; the swap then flies the actual console card up (matched geometry)
/// to cover the screen and `.released` tells the redesign to retract it + run its landing
/// timeline, which resets back to `.idle` when done.
enum MorphPhase { case idle, stretching, released }

/// Top-level navigation, independent of the morph `stage` axis: the app opens on the
/// home screen; the home "+" opens the brain dump.
enum AppRoute { case home, brainDump }

/// Drives the prototype's three-stage flow. `replay()` re-triggers the one-time
/// onboarding+morph so it can be reviewed repeatedly on-device.
@MainActor
final class AppFlowCoordinator: ObservableObject {
    @Published var stage: AppStage = .current
    @Published var route: AppRoute = .home
    /// Morph sub-phase. Set WITHOUT `withAnimation` — each view animates it with its
    /// own curve via `.animation(_, value:)` so the overlay/sections/console can move
    /// on different timings off one state change.
    @Published var morphPhase: MorphPhase = .idle
    /// True while the redesign is being presented via the direct "+" open (slide-up
    /// entrance) rather than the morph. Mutually exclusive with `morphPhase == .released`.
    @Published var directOpen = false

    /// Persisted: once the onboarding/morph has been seen, "+" opens the redesign directly.
    /// The home admin panel's "Reset onboarding" clears this (re-arms the first-run morph).
    private static let onboardingSeenKey = "numo.hasSeenOnboarding"
    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.onboardingSeenKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.onboardingSeenKey) }
    }

    init() {
        // Test hook: NUMO_ONBOARDED=reset clears the persisted flag (re-arm the first-run
        // onboarding); =yes marks it seen (so "+" goes direct).
        switch ProcessInfo.processInfo.environment["NUMO_ONBOARDED"] {
        case "reset", "no": hasSeenOnboarding = false
        case "yes": hasSeenOnboarding = true
        default: break
        }

        // Debug boot hooks (mirror NUMO_SCROLL):
        //   NUMO_START=overlay  → straight into the brain dump with the overlay already shown (static, for screenshots)
        //   NUMO_START=open     → into the brain dump at .current so the entrance plays, then the overlay reveals
        //   NUMO_START=redesign → straight into the Stage 3 redesigned screen (static, for screenshots)
        //   NUMO_START=direct   → straight into the redesign's direct "+" slide-up entrance
        switch ProcessInfo.processInfo.environment["NUMO_START"] {
        case "direct":
            // Overlay the slide-up over home (route stays .home).
            directOpen = true
        case "overlay":
            route = .brainDump
            stage = .onboarding
        case "open":
            route = .brainDump
            stage = .current
        case "redesign":
            route = .brainDump
            stage = .redesigned
        case "morph":
            // Boots into the static overlay, then auto-plays the full morph — lets the
            // whole choreography be captured headlessly (screenshot burst / recording).
            route = .brainDump
            stage = .onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.morphToRedesign()
            }
        default:
            break
        }
    }

    /// Home → BrainDump. Switch instantly (the section slide-up is the motion). The Stage 2
    /// overlay is revealed by `showOnboardingAfterEntrance()` once that slide-up finishes —
    /// not here — so the overlay lands after the brain dump has fully appeared.
    func openBrainDump() {
        stage = .current
        morphPhase = .idle
        directOpen = false
        route = .brainDump
    }

    /// The home "+" entry point: first time plays the onboarding/morph; once it's been seen
    /// (persisted), opens the redesign directly with the slide-up entrance.
    func openFromPlus() {
        if hasSeenOnboarding { openRedesignedDirect() } else { openBrainDump() }
    }

    /// Direct open: the redesign mounts as a bottom-sheet OVERLAY over the home screen
    /// (route stays `.home`, so home shows behind the rising sheet). `RedesignedScreen`'s
    /// `viaSlideUp` timeline rises over home, touches the top, reveals the bg, then lands.
    func openRedesignedDirect() {
        morphPhase = .idle
        route = .home
        directOpen = true
    }

    /// BrainDump → Home.
    func goHome() { withAnimation(.easeOut(duration: 0.25)) { directOpen = false; route = .home } }

    /// Called by `BrainDumpScreen` as its entrance ("sections slide up") is landing — fades
    /// the Stage 2 overlay in so it flows continuously out of the slide-up (timing tuned in
    /// `BrainDumpEntrance`). Guarded so it only fires for the plain brain dump (not when
    /// already onboarding/redesigned).
    func showOnboardingAfterEntrance() {
        guard route == .brainDump, stage == .current else { return }
        withAnimation(.easeOut(duration: 0.3)) { stage = .onboarding } // was BrainDumpEntrance.overlayFade (Stage-78 native braindump removal)
    }

    func showOnboarding() { withAnimation(.smooth(duration: 0.4)) { stage = .onboarding } }

    /// The morph sequencer ("See how"): Act I — the form draws down on Stage 1 and holds;
    /// then the screen swaps instantly to the redesign, which owns Acts II + III (the white
    /// canvas flies up to cover, retracts to reveal the new bg, then the chrome/bottom/
    /// placeholder/keyboard land — see `RedesignedScreen.runReleaseTimeline`) and resets
    /// `morphPhase` to `.idle` when done.
    func morphToRedesign() {
        guard stage == .onboarding, morphPhase == .idle else { return }
        hasSeenOnboarding = true   // user committed to "See how" → later "+" opens redesign directly
        directOpen = false
        morphPhase = .stretching
        DispatchQueue.main.asyncAfter(deadline: .now() + MorphChoreo.stretchDuration) { [weak self] in
            guard let self, self.morphPhase == .stretching else { return }
            // Instant swap (no animation): the redesign's first frame reconstructs the
            // stretched console exactly, so the swap is invisible. The redesign then
            // animates the cover/reveal/landing itself (`runReleaseTimeline`).
            self.stage = .redesigned
            self.morphPhase = .released
        }
    }

    func replay() {
        morphPhase = .idle
        directOpen = false
        withAnimation(.smooth(duration: 0.4)) { stage = .current }
    }

    /// DEBUG: hidden gesture cycles stages until the real triggers (overlay dismiss) exist.
    func debugAdvance() {
        switch stage {
        case .current: showOnboarding()
        case .onboarding: morphToRedesign()
        case .redesigned: replay()
        }
    }
}
