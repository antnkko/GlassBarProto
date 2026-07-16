/**
 * Stage 49 — 1:1 mirror of `ios/Numo/Morph/MorphChoreo.swift` +
 * `BrainDumpEntrance.swift` (the source of truth for every timing/spring/
 * offset in the onboarding morph and the braindump open/close slides).
 *
 * Conversion rules (same as src/braindump/motion.ts):
 *   .spring(duration: d, bounce: b)          → {duration: d*1000, dampingRatio: 1 − b}
 *   .spring(response: r, dampingFraction: f) → {mass: 1, stiffness: (2π/r)², damping: f·2·√stiffness}
 *   .smooth(duration: d)                     → {duration: d*1000, dampingRatio: 1}
 *   .easeOut(duration: d)                    → withTiming {duration: d*1000, Easing.out(Easing.quad)}
 *
 * Keep names identical to the Swift constants so the two files diff cleanly.
 */
import {Easing} from 'react-native-reanimated';
import type {WithSpringConfig, WithTimingConfig} from 'react-native-reanimated';

// ── Entrance cascade (BrainDumpEntrance.swift) ──────────────────────────────
// All blocks release SIMULTANEOUSLY one frame after mount; the cascade look
// comes purely from the different start offsets (no staggered delays).
// Spring is the donor RN `Animated.spring({speed:15.5, bounciness:10})`
// analytic form — mass 1, stiffness ≈ 416.5, damping ≈ 24.3.
export const Entrance = {
  spring: {mass: 1, stiffness: 416.5, damping: 24.3} as WithSpringConfig,
  /** Per-section start translateY (pt) → 0. */
  banner: 30,
  console: 30,
  subtasks: 50,
  settings: 70, // effort + settings block
  time: 90, // time + order + tags + notes block
  /** Overlay fade-in starts this long after the entrance begins. */
  overlayRevealDelay: 120,
  /** Overlay fade-in duration (opacity 0→1). */
  overlayFade: {duration: 300, easing: Easing.out(Easing.quad)} as WithTimingConfig,
} as const;

// ── MorphChoreo — Acts I / II / III (the "See how" morph) ───────────────────
export const MorphChoreo = {
  // Act I — stretch (the drawn bow: DOWN only, no rebound)
  /** How long the draw-down is held before the release fires. */
  stretchDuration: 1500,
  overlayFadeOut: {duration: 180, easing: Easing.out(Easing.quad)} as WithTimingConfig,
  /** .spring(duration: 0.7, bounce: 0) — smooth, non-overshooting draw-down. */
  drawDown: {duration: 700, dampingRatio: 1} as WithSpringConfig,
  /** Tension pull: banner + console drawn down a touch (down only). */
  consolePull: 30,
  /** The console grows by this much — pushes ALL sections down as one block. */
  consoleGrowth: 700,

  // Act II — the reconstructed console flies up to full cover, then retracts
  /** Reconstructed console's top at `.start` (tune so the swap has no jump). */
  coverStart: 250,
  /** .spring(duration: 0.38, bounce: 0.12) — snappy rise to full cover. */
  riseSpring: {duration: 380, dampingRatio: 0.88} as WithSpringConfig,
  /** Flight time before the bg swaps (blue+banner → Figma) under full cover. */
  riseDur: 380,
  /** Old back/Public header flies this far up during the rise. */
  ghostRise: 120,
  /** Hold full white a beat, then retract to reveal the Figma background. */
  coverHold: 200,
  /** .spring(duration: 0.6, bounce: 0.18). */
  retractSpring: {duration: 600, dampingRatio: 0.82} as WithSpringConfig,

  // Act III — landing (launched off the retract's settle)
  /** .spring(duration: 0.5, bounce: 0.40) — top chrome drops in with a bounce. */
  newHeaderSpring: {duration: 500, dampingRatio: 0.6} as WithSpringConfig,
  newHeaderDrop: -28,
  /** .spring(duration: 0.55, bounce: 0.22). */
  bottomBarSpring: {duration: 550, dampingRatio: 0.78} as WithSpringConfig,
  bottomBarRise: 280,
  /** Buttons launch this long after the retract START (during its settle). */
  buttonsLead: 300,
  /** Upper chrome leads the lower group by a hair. */
  buttonsStagger: 60,
  /** Placeholder blur-swap + keyboard fire this long after the buttons. */
  textAfterButtons: 450,
  /** .smooth(duration: 0.45). */
  placeholderSwap: {duration: 450, dampingRatio: 1} as WithSpringConfig,
} as const;

// ── Direct "+" open/close (bottom-sheet slide-up / canvas-led slide-down) ───
export const Slide = {
  // OPEN: rise to full cover (quick, no overshoot), then drop to rest with a bounce.
  /** .spring(duration: 0.18, bounce: 0). */
  riseSpring: {duration: 180, dampingRatio: 1} as WithSpringConfig,
  riseDur: 180,
  coverHold: 0,
  /** .spring(duration: 0.32, bounce: 0.34) — the signature reveal bounce. */
  retractSpring: {duration: 320, dampingRatio: 0.66} as WithSpringConfig,
  /** Chrome lands this long after the drop starts. */
  buttonsLead: 100,
  /** Bottom group enters from a short rise (not full keyboard height). */
  bottomBarRise: 40,
  bottomBarDelay: 60,

  // CLOSE: anticipation stretch UP, then the canvas drops straight off the bottom.
  closeStretch: 24,
  /** .spring(duration: 0.10, bounce: 0.2). */
  closeStretchSpring: {duration: 100, dampingRatio: 0.8} as WithSpringConfig,
  closeStretchDur: 100,
  /** .spring(duration: 0.32, bounce: 0). */
  closeDropSpring: {duration: 320, dampingRatio: 1} as WithSpringConfig,
  closeDropDur: 320,
  /** Bg fades faster than the drop → reveals home early. */
  closeBgFade: {duration: 180, easing: Easing.out(Easing.quad)} as WithTimingConfig,
  closeBottomFade: {duration: 120, easing: Easing.out(Easing.quad)} as WithTimingConfig,
} as const;

// ── Onboarding overlay scrim (OnboardingOverlay.swift) ──────────────────────
/** White vertical gradient: transparent at loc 0.072 → solid white at 0.615. */
export const OverlayScrim = {
  transparentStop: 0.072,
  solidStop: 0.615,
} as const;
