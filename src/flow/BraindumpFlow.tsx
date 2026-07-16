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
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {BraindumpBottomBar} from '../braindump/BraindumpBottomBar';
import {createFlowBus} from '../braindump/flowEvents';
import {color} from '../braindump/tokens';
import {MorphChoreo, Slide} from './choreo';
import {RedesignedCanvas} from './RedesignedCanvas';

const SHEET_TOP_RADIUS = 48; // Metrics.Redesign.sheetTopRadius (resting)
const CARD_RADIUS = 36; // Metrics.cardRadius — kept through the flight

interface Props {
  /** The flow finished closing — unmount the overlay. */
  onClosed: () => void;
  /** Glass shadow knobs (dev-panel), same values the native flow receives. */
  shadow: {opacity: number; radius: number};
  /** Voice button inner glow (dev-panel). */
  voiceGlow: {radius: number; opacity: number};
}

export function BraindumpFlow({onClosed, shadow, voiceGlow}: Props) {
  const insets = useSafeAreaInsets();
  const {height: windowH, width: windowW} = useWindowDimensions();
  const flowBus = useRef(createFlowBus()).current;
  const inputRef = useRef<TextInput | null>(null);
  const [whenOpen, setWhenOpen] = useState(false);
  const closing = useRef(false);

  // The animated surfaces. Initial values = the parked slide-up state
  // (sheet below the screen, bg transparent so Home shows through, chrome out).
  const sheetTop = useSharedValue(windowH);
  const closeY = useSharedValue(0);
  const radius = useSharedValue(CARD_RADIUS);
  const bgOpacity = useSharedValue(0);
  const chromeIn = useSharedValue(0);

  // OPEN — runSlideUpTimeline: keyboard rises with the canvas; the white
  // canvas rises to touch the top (bg unseen), the artwork is set under full
  // cover, then the canvas drops to rest with a bounce — revealing it.
  useEffect(() => {
    inputRef.current?.focus();
    const downDelay = Slide.riseDur + Slide.coverHold;
    sheetTop.value = withSequence(
      withSpring(0, Slide.riseSpring),
      withSpring(insets.top, Slide.retractSpring),
    );
    // Set the Figma bg under full cover — an instant flip, never animated.
    bgOpacity.value = withDelay(Slide.riseDur, withTiming(1, {duration: 1}));
    // Corner radius stays 36 through the flight; only the resting sheet is 48.
    radius.value = withDelay(downDelay, withSpring(SHEET_TOP_RADIUS, Slide.retractSpring));
    // Chrome lands after the bg is revealed; the bottom group launches early
    // so it rides up with the keyboard's inertia.
    chromeIn.value = withDelay(
      downDelay + Slide.buttonsLead,
      withSpring(1, MorphChoreo.newHeaderSpring),
    );
    const barBeat = setTimeout(() => flowBus.emit('barEnterSlide'), Slide.bottomBarDelay);
    return () => clearTimeout(barBeat);
    // Mount-only: the timeline runs once per open (fresh mount per open).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // CLOSE — runSlideDownTimeline: anticipation stretch up, then the canvas
  // drops straight off the bottom; keyboard dismisses simultaneously; the bg
  // fades out faster than the drop so Home shows early; the chrome is cropped
  // by the descending canvas edge (counter-translate, see RedesignedCanvas).
  const close = useCallback(() => {
    if (closing.current) {
      return;
    }
    closing.current = true;
    flowBus.emit('closing'); // bottom cluster fades out fast
    Keyboard.dismiss();
    bgOpacity.value = withTiming(0, Slide.closeBgFade);
    closeY.value = withSequence(
      withSpring(-Slide.closeStretch, Slide.closeStretchSpring),
      withSpring(windowH, Slide.closeDropSpring, finished => {
        'worklet';

        if (finished) {
          runOnJS(onClosed)();
        }
      }),
    );
  }, [bgOpacity, closeY, flowBus, onClosed, windowH]);

  const bgStyle = useAnimatedStyle(() => ({opacity: bgOpacity.value}));
  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{translateY: sheetTop.value + closeY.value}],
    borderTopLeftRadius: radius.value,
    borderTopRightRadius: radius.value,
  }));

  return (
    <View style={styles.root}>
      {/* Full-bleed painterly artwork, top-anchored and window-sized so the
          keyboard/insets never resize it. Transparent until the sheet covers
          the screen (Home shows through the rise), instant flip under cover. */}
      <Animated.Image
        source={require('../assets/redesign_bg.jpg')}
        style={[styles.bg, {width: windowW, height: windowH}, bgStyle]}
        resizeMode="cover"
      />

      {/* The white canvas: full-window layout, positioned by translateY only;
          clips its content (the close crop mechanism relies on this clip). */}
      <Animated.View style={[styles.sheet, {height: windowH}, sheetStyle]}>
        <RedesignedCanvas
          whenOpen={whenOpen}
          shadow={shadow}
          inputRef={inputRef}
          chromeIn={chromeIn}
          closeY={closeY}
          onCloseTap={close}
          onClearTap={() => {
            flowBus.emit('clearWhen');
            setWhenOpen(false);
          }}
          onConfirmTap={() => setWhenOpen(false)}
          onBackdropTap={() => setWhenOpen(false)}
        />
      </Animated.View>

      {/* The RN-owned bottom-bar cluster (chip ⇄ When-picker morph), riding
          the keyboard — enters on the 'barEnterSlide' beat. */}
      <BraindumpBottomBar
        whenOpen={whenOpen}
        onWhenOpenChange={setWhenOpen}
        flowBus={flowBus}
        voiceGlow={voiceGlow}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {position: 'absolute', top: 0, left: 0, right: 0, bottom: 0},
  bg: {position: 'absolute', top: 0, left: 0},
  sheet: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    backgroundColor: color.white,
    borderTopLeftRadius: SHEET_TOP_RADIUS,
    borderTopRightRadius: SHEET_TOP_RADIUS,
    overflow: 'hidden',
  },
});
