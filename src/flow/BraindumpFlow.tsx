/**
 * Stage 50/51 — the RN braindump flow root (the NumoFlowView replacement
 * behind the debug toggle). Owns the full-bleed background, the white sheet
 * (position + clip), the RN bottom-bar cluster, the local flow bus and the
 * OPEN/CLOSE slide timelines (`runSlideUpTimeline` / `runSlideDownTimeline`
 * ported from RedesignedScreen.swift — every beat on the UI thread, zero
 * setState mid-animation). Stages 52–54 add the onboarding path.
 *
 * Geometry: the sheet is laid out full-window (top 0, height windowH) and
 * positioned purely by translateY = sheetTop + closeY:
 *   OPEN  sheetTop: windowH → 0 (rise, flat) → safeTop (drop, bounce)
 *   CLOSE closeY:   0 → −24 (anticipation) → windowH (drop off the bottom)
 * The chrome counter-translates by −closeY inside the clipped sheet, so the
 * descending top edge CROPS it in place (the native header-crop mechanism).
 */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {Keyboard, StyleSheet, TextInput, View, useWindowDimensions} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import Animated, {
  runOnJS,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {BAR_BEAT, BraindumpBottomBar} from '../braindump/BraindumpBottomBar';
import type {PickerKind} from '../braindump/MorphingShell';
import {createFlowBus} from '../braindump/flowEvents';
import {color} from '../braindump/tokens';
import {BrainDumpList} from './BrainDumpList';
import {Entrance, MorphChoreo, Slide} from './choreo';
import {setSeenOnboarding} from './flowState';
import {OnboardingOverlay} from './OnboardingOverlay';
import {RedesignedCanvas} from './RedesignedCanvas';

const SHEET_TOP_RADIUS = 48; // Metrics.Redesign.sheetTopRadius (resting)
const CARD_RADIUS = 36; // Metrics.cardRadius — kept through the flight

/** The stretched console's top edge below the safe area (the morph swap
 *  position): (bannerHeight − bannerOverlap) + cardTopMargin + consolePull. */
const CONSOLE_TOP = 128 - 64 + 3 + MorphChoreo.consolePull; // 97

/** Stage 57: the rise targets a few px ABOVE the top edge — the duration
 *  spring's asymptote left the sheet visibly short of y=0 before the retract
 *  pulled it back (the canvas never touched the physical top). */
const COVER_OVERSHOOT = 12;

/** Stage 59: the close's up-stretch now travels to the PHYSICAL top (safeTop
 *  + overshoot ≈ 70pt, vs the native 24) — same anticipation feel, slightly
 *  longer perceptual duration for the longer travel. */
const CLOSE_TO_TOP_SPRING = {duration: 160, dampingRatio: 0.8};

interface Props {
  /** The flow finished closing — the overlay is hidden/reset (persistent
   *  direct path) or should unmount (onboarding path). */
  onClosed: () => void;
  /** Stage 58 persistent direct path: the flow stays MOUNTED and parked;
   *  each bump of openSeq re-arms and plays the open timeline the same frame
   *  (no per-open mount cost — the tap-latency fix). 0 = stay parked. */
  openSeq?: number;
  /** First run (onboarding unseen): mount the Stage-1 brain dump with the
   *  entrance cascade instead of the direct slide-up, then the overlay and
   *  the 3-act "See how" morph (AppFlowCoordinator's openFromPlus path). */
  onboarding?: boolean;
  /** The morph landed — App persists the seen flag. */
  onOnboardingComplete?: () => void;
  /** Dev-only (autoplay): trigger "See how" this long after mount. */
  autoMorphAfterMs?: number;
  /** Stage 57: transform-only spawn mechanic for the Liquid Glass groups
   *  (alpha over UIGlassEffect renders broken/black on device). */
  glassSpawn?: 'clip' | 'pop';
  /** Picker state ('none' | 'when' | 'routine') — owned by App (single
   *  source for native + RN paths, and drivable by the dev autoplay). */
  openPicker: PickerKind;
  onOpenPickerChange: (picker: PickerKind) => void;
  /** Dev hook (glassbar://closeflow): a bump runs the close timeline —
   *  headless capture of the slide-down, mirroring the native NUMO_WHEN=anim. */
  closeSeq?: number;
  /** Glass shadow knobs (dev-panel), same values the native flow receives. */
  shadow: {opacity: number; radius: number};
  /** Voice button inner glow (dev-panel). */
  voiceGlow: {radius: number; opacity: number};
}

export function BraindumpFlow({
  onClosed,
  openSeq = 0,
  onboarding = false,
  onOnboardingComplete,
  autoMorphAfterMs,
  glassSpawn = 'clip',
  openPicker,
  onOpenPickerChange,
  closeSeq = 0,
  shadow,
  voiceGlow,
}: Props) {
  const insets = useSafeAreaInsets();
  const {height: windowH, width: windowW} = useWindowDimensions();
  const flowBus = useRef(createFlowBus()).current;
  const inputRef = useRef<TextInput | null>(null);
  const closing = useRef(false);
  const morphStarted = useRef(false);
  // ONE React commit at Act I start (disables Stage-1 scroll, guards taps).
  const [stretching, setStretching] = useState(false);
  // Persistent path: gates hit-testing while parked (tiny commit per open —
  // the full-subtree mount this replaces was the tap delay).
  const [active, setActive] = useState(onboarding);

  // The animated surfaces. Initial values: direct open = the parked slide-up
  // state (sheet below the screen, Home showing through); onboarding = the
  // reconstructed swap state (sheet hidden at the stretched console's top).
  const sheetTop = useSharedValue(onboarding ? insets.top + CONSOLE_TOP : windowH);
  const closeY = useSharedValue(0);
  const radius = useSharedValue(CARD_RADIUS);
  const bgOpacity = useSharedValue(0);
  const chromeIn = useSharedValue(0);
  // Onboarding-only drivers.
  const canvasOpacity = useSharedValue(onboarding ? 0 : 1);
  const stretchP = useSharedValue(0);
  const overlayOpacity = useSharedValue(0);
  const ghost = useSharedValue(0);
  const placeholderP = useSharedValue(0);
  // Stage 58: UI-thread beat channel into the bottom cluster (JS timers
  // drifted → the bar arrived late and the open read jerky).
  const barBeat = useSharedValue<number>(BAR_BEAT.idle);
  // Stage 59: gates the cover flip's direction (1 while closing).
  const closeIntent = useSharedValue(0);

  // Park every animated value at the pre-open pose (used at mount and after
  // every close — the persistent flow re-arms instead of remounting). Keep
  // EVERY value the timelines touch in here.
  const park = useCallback(() => {
    sheetTop.value = windowH;
    closeY.value = 0;
    radius.value = CARD_RADIUS;
    bgOpacity.value = 0;
    chromeIn.value = 0;
    canvasOpacity.value = 1;
    barBeat.value = BAR_BEAT.reset;
    closeIntent.value = 0;
    closing.current = false;
    // Release the first responder so the NEXT open's focus() re-presents the
    // keyboard (a stale responder on the hidden input swallowed it).
    inputRef.current?.blur();
  }, [barBeat, bgOpacity, canvasOpacity, chromeIn, closeIntent, closeY, radius, sheetTop, windowH]);

  // OPEN — runSlideUpTimeline: keyboard rises with the canvas; the white
  // canvas rises to touch the top (bg unseen), the artwork is set under full
  // cover, then the canvas drops to rest with a bounce — revealing it. Every
  // VISUAL beat is scheduled on the UI thread (withDelay), zero JS timers.
  // The onboarding path never runs it (Stage-1 mounts with its own entrance).
  useEffect(() => {
    if (onboarding || openSeq === 0) {
      return;
    }
    setActive(true);
    park();
    // Focus on the NEXT frame, after the activation commit — focusing the
    // hidden pre-mounted input in the same tick failed to present the
    // keyboard (the native flow defers focus one runloop for the same
    // reason). The keyboard still rises together with the canvas.
    requestAnimationFrame(() => inputRef.current?.focus());
    const downDelay = Slide.riseDur + Slide.coverHold;
    // Rise past the top edge (COVER_OVERSHOOT) so the cover is real; the bg
    // flips via the sheetTop reaction below the moment coverage happens.
    sheetTop.value = withSequence(
      withSpring(-COVER_OVERSHOOT, Slide.riseSpring),
      withSpring(insets.top, Slide.retractSpring),
    );
    // Corner radius stays 36 through the flight; only the resting sheet is 48.
    radius.value = withDelay(downDelay, withSpring(SHEET_TOP_RADIUS, Slide.retractSpring));
    // Chrome lands after the bg is revealed; the bottom group launches early
    // so it rides up with the keyboard's inertia.
    chromeIn.value = withDelay(
      downDelay + Slide.buttonsLead,
      withSpring(1, MorphChoreo.newHeaderSpring),
    );
    barBeat.value = withDelay(
      Slide.bottomBarDelay,
      withTiming(BAR_BEAT.enterSlide, {duration: 1}),
    );
    // Per-open trigger (persistent mount).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [openSeq]);

  // After the drop lands: persistent path parks + deactivates (stays
  // mounted); the onboarding path unmounts via onClosed as before.
  const onCloseSettled = useCallback(() => {
    if (!onboarding) {
      park();
      setActive(false);
    }
    onClosed();
  }, [onClosed, onboarding, park]);

  // CLOSE — runSlideDownTimeline: anticipation stretch up, then the canvas
  // drops straight off the bottom; keyboard dismisses simultaneously; the bg
  // fades out faster than the drop so Home shows early; the chrome is cropped
  // by the descending canvas edge (counter-translate, see RedesignedCanvas).
  const close = useCallback(() => {
    if (closing.current) {
      return;
    }
    closing.current = true;
    closeIntent.value = 1;
    barBeat.value = BAR_BEAT.closing; // bottom cluster hides fast (UI thread)
    Keyboard.dismiss();
    // Stage 59 (user-requested): the canvas first rides UP to the physical
    // top edge — visually "taking the picture with it" — the artwork is
    // flipped out UNDER the cover (reaction below), then the canvas drops,
    // revealing Home. (Replaces the native −24 anticipation + parallel fade.)
    closeY.value = withSequence(
      withSpring(-(insets.top + COVER_OVERSHOOT), CLOSE_TO_TOP_SPRING),
      withSpring(windowH, Slide.closeDropSpring, finished => {
        'worklet';

        if (finished) {
          runOnJS(onCloseSettled)();
        }
      }),
    );
  }, [barBeat, closeIntent, closeY, insets.top, onCloseSettled, windowH]);

  // Dev hook: glassbar://closeflow bumps closeSeq → run the close timeline.
  // Fire only on a VALUE CHANGE — `close`'s identity shifts across renders,
  // and re-running the effect after park() reset the closing guard used to
  // re-trigger a stray close mid-open (the second-open bug).
  const lastCloseSeq = useRef(0);
  useEffect(() => {
    if (closeSeq > 0 && closeSeq !== lastCloseSeq.current) {
      lastCloseSeq.current = closeSeq;
      close();
    }
  }, [closeSeq, close]);

  // ── The 3-act "See how" morph (AppFlowCoordinator.morphToRedesign +
  //    RedesignedScreen.runReleaseTimeline), all springs on the UI thread ──
  const runMorph = useCallback(() => {
    if (morphStarted.current) {
      return;
    }
    morphStarted.current = true;
    setStretching(true); // one commit: scroll off (Act I disables scroll)

    // Every VISUAL beat below is scheduled on the UI thread from t0
    // (withDelay) — JS timers drifted and made the morph read stretched.
    const T = MorphChoreo.stretchDuration;
    const retractDelay = MorphChoreo.riseDur + MorphChoreo.coverHold;
    const buttonsDelay = retractDelay + MorphChoreo.buttonsLead;

    // Act I — the drawn bow: overlay out fast, banner+console pull down,
    // console swells 700 pushing the sections off as one block. Held 1500ms.
    overlayOpacity.value = withTiming(0, MorphChoreo.overlayFadeOut);
    stretchP.value = withSpring(1, MorphChoreo.drawDown);

    // Invisible swap at T: the canvas is pre-mounted at the reconstructed
    // frame — the flip is a shared-value write, zero React commits.
    canvasOpacity.value = withDelay(T, withTiming(1, {duration: 1}));

    // Act II — fly up to full cover (past the top edge, see COVER_OVERSHOOT);
    // ghost header out on the same spring; the bg swaps to the artwork the
    // moment coverage is REAL (sheetTop reaction); hold; retract to rest.
    sheetTop.value = withDelay(
      T,
      withSequence(
        withSpring(-COVER_OVERSHOOT, MorphChoreo.riseSpring),
        withDelay(MorphChoreo.coverHold, withSpring(insets.top, MorphChoreo.retractSpring)),
      ),
    );
    ghost.value = withDelay(T, withSpring(1, MorphChoreo.riseSpring));
    radius.value = withDelay(
      T + retractDelay,
      withSpring(SHEET_TOP_RADIUS, MorphChoreo.retractSpring),
    );

    // Act III — chrome drops in during the retract's settle; the bottom
    // cluster rises +60ms later; then the placeholder swap + keyboard.
    chromeIn.value = withDelay(
      T + buttonsDelay,
      withSpring(1, MorphChoreo.newHeaderSpring),
    );
    barBeat.value = withDelay(
      T + buttonsDelay + MorphChoreo.buttonsStagger,
      withTiming(BAR_BEAT.enterMorph, {duration: 1}),
    );
    placeholderP.value = withDelay(
      T + buttonsDelay + MorphChoreo.textAfterButtons,
      withSpring(1, MorphChoreo.placeholderSwap),
    );
    // Non-visual side effects (keyboard focus, persistence) stay on a timer.
    setTimeout(() => {
      requestAnimationFrame(() => inputRef.current?.focus());
      setSeenOnboarding();
      onOnboardingComplete?.();
    }, T + buttonsDelay + MorphChoreo.textAfterButtons);
  }, [
    barBeat,
    canvasOpacity,
    chromeIn,
    ghost,
    insets.top,
    onOnboardingComplete,
    overlayOpacity,
    placeholderP,
    radius,
    sheetTop,
    stretchP,
  ]);

  // Dev-only autoplay: trigger "See how" headlessly.
  useEffect(() => {
    if (onboarding && autoMorphAfterMs != null) {
      const id = setTimeout(runMorph, autoMorphAfterMs);
      return () => clearTimeout(id);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Cover flips, both directions gated on ACTUAL coverage (top edge at/past
  // y=0) — never on blind timers (Stage 57/59):
  //  - OPEN: artwork appears the moment the rising sheet covers the screen.
  //  - CLOSE: artwork disappears the moment the up-stretch covers the screen
  //    (closeIntent gates it so the open's cover doesn't flip it back off).
  useAnimatedReaction(
    () => sheetTop.value + closeY.value,
    top => {
      if (top <= 0) {
        if (closeIntent.value === 1 && bgOpacity.value > 0) {
          bgOpacity.value = 0;
        } else if (closeIntent.value === 0 && bgOpacity.value < 1) {
          bgOpacity.value = 1;
        }
      }
    },
  );

  const bgStyle = useAnimatedStyle(() => ({opacity: bgOpacity.value}));
  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{translateY: sheetTop.value + closeY.value}],
    borderTopLeftRadius: radius.value,
    borderTopRightRadius: radius.value,
  }));

  const canvasStyle = useAnimatedStyle(() => ({opacity: canvasOpacity.value}));

  return (
    <View style={styles.root} pointerEvents={active ? 'box-none' : 'none'}>
      {/* First run: Stage-1 brain dump + onboarding overlay UNDER everything —
          the morph's rising sheet covers it, the artwork then hides it. */}
      {onboarding && (
        <View style={[styles.root, styles.vibrantCanvas]}>
          <BrainDumpList
            onBack={onClosed}
            stretchP={stretchP}
            scrollEnabled={!stretching}
            onEntranceStart={() => {
              // Overlay reveal overlaps the entrance tail (+120ms, easeOut 300).
              overlayOpacity.value = withDelay(
                Entrance.overlayRevealDelay,
                withTiming(1, Entrance.overlayFade),
              );
            }}
          />
          <OnboardingOverlay opacity={overlayOpacity} onSeeHow={runMorph} />
        </View>
      )}

      {/* Full-bleed painterly artwork, top-anchored and window-sized so the
          keyboard/insets never resize it. Transparent until the sheet covers
          the screen (Home / Stage-1 shows through), instant flip under cover. */}
      <Animated.Image
        source={require('../assets/redesign_bg.jpg')}
        style={[styles.bg, {width: windowW, height: windowH}, bgStyle]}
        resizeMode="cover"
      />

      {/* The white canvas: full-window layout, positioned by translateY only;
          clips its content (the close crop mechanism relies on this clip).
          In onboarding it pre-mounts HIDDEN at the reconstructed swap frame —
          the release flips only shared values. */}
      <Animated.View style={[styles.sheet, {height: windowH}, sheetStyle, canvasStyle]}>
        <RedesignedCanvas
          resetSeq={openSeq}
          openPicker={openPicker}
          shadow={shadow}
          inputRef={inputRef}
          chromeIn={chromeIn}
          closeY={closeY}
          glassSpawn={glassSpawn}
          morph={onboarding ? {ghost, placeholderP} : undefined}
          onCloseTap={close}
          onClearTap={() => {
            flowBus.emit('clearWhen');
            onOpenPickerChange('none');
          }}
          onConfirmTap={() => onOpenPickerChange('none')}
          onBackdropTap={() => onOpenPickerChange('none')}
        />
      </Animated.View>

      {/* The RN-owned bottom-bar cluster (chip ⇄ When-picker morph), riding
          the keyboard — enters on the 'barEnterSlide' beat. */}
      <BraindumpBottomBar
        openPicker={openPicker}
        onOpenPickerChange={onOpenPickerChange}
        flowBus={flowBus}
        voiceGlow={voiceGlow}
        glassSpawn={glassSpawn}
        beat={barBeat}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {position: 'absolute', top: 0, left: 0, right: 0, bottom: 0},
  vibrantCanvas: {backgroundColor: color.vibrant},
  bg: {position: 'absolute', top: 0, left: 0},
  sheet: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    backgroundColor: color.white,
    borderTopLeftRadius: SHEET_TOP_RADIUS,
    borderTopRightRadius: SHEET_TOP_RADIUS,
    borderCurve: 'continuous', // Apple squircle — matches the SwiftUI .continuous style
    overflow: 'hidden',
  },
});
