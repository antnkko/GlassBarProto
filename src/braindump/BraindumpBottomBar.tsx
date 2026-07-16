/**
 * Stage 41 — the RN-owned braindump bottom-bar cluster, rendered as a sibling
 * ABOVE the transparent NumoFlow overlay. Owns: keyboard riding (RN Keyboard
 * events fire for the native TextField's keyboard), the entry/exit beats
 * (played on events emitted by the native timelines), the white backdrop
 * gradient and the tap-outside scrim. The morphing shell + picker + voice
 * live in MorphingShell.
 */
import React, {useEffect, useRef} from 'react';
import {Dimensions, Keyboard, Pressable, StyleSheet} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import {LinearGradient} from 'expo-linear-gradient';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {FlowBus} from './flowEvents';
import {MorphingShell, MorphingShellHandle} from './MorphingShell';
import {bar, color, entry} from './tokens';
import {closeSpring, entrySpring, fadeOut120, keyboardEasing, openSpring} from './motion';

// Native header geometry (RedesignedScreen / Metrics.WhenPicker): the sheet
// top is at the safe-area top, the header buttons sit headerPadV below it and
// are closeSize tall. So the header BOTTOM = safeTop + headerPadV + closeSize,
// and the header's own top gap = headerPadV. The open picker's top gap should
// match that gap → picker top target = headerBottom + headerPadV.
const HEADER_PAD_V = 20;
const CLOSE_SIZE = 48;

/** Stage 57 'clip' spawn park: the glass content sits fully below the screen
 *  bottom / behind the keyboard (content ≈142 + shadow bleed) pre-beat. */
const BAR_PARK = 180;

type Props = {
  whenOpen: boolean;
  onWhenOpenChange: (open: boolean) => void;
  flowBus: FlowBus;
  /** Voice button inner glow (dev-panel tunable). */
  voiceGlow?: {radius: number; opacity: number};
  /** Stage 57: transform-only spawn for the glass content (alpha over
   *  UIGlassEffect renders broken/black on device); the white gradient
   *  backdrop still fades — it's a plain RN view. */
  glassSpawn?: 'clip' | 'pop';
  onVoiceTap?: () => void;
};

export function BraindumpBottomBar({
  whenOpen,
  onWhenOpenChange,
  flowBus,
  voiceGlow,
  glassSpawn = 'clip',
  onVoiceTap,
}: Props) {
  // Keyboard top — the cluster sits right above it (the native bar used the
  // bottom safe-area inset, which the keyboard replaces wholesale).
  const kbH = useSharedValue(0);
  // Entry/exit choreography (native MorphChoreo beats, event-driven). The
  // glass content hides pre-beat by TRANSFORM only: parked behind the
  // keyboard/bottom edge in BOTH modes (scale must never hit 0 — a degenerate
  // matrix breaks hosted native rendering).
  const entryY = useSharedValue<number>(BAR_PARK);
  const contentScale = useSharedValue(1);
  // The gradient backdrop's fade (plain RN view — alpha is safe here).
  const entryOpacity = useSharedValue(0);
  // Open progress (0..1) — drives the symmetric-gap lift so the picker's top
  // gap to the header matches the header's own top gap (device-independent).
  const openP = useSharedValue(0);
  // Measured open picker height — a shared value, NOT React state: the
  // cluster worklet reads it, and a setState here re-rendered the cluster
  // mid-open when the measurement landed (Stage 55).
  const openH = useSharedValue(0);

  const insets = useSafeAreaInsets();
  const screenH = Dimensions.get('window').height;
  const pickerTopTarget = insets.top + HEADER_PAD_V + CLOSE_SIZE + HEADER_PAD_V;

  const shellRef = useRef<MorphingShellHandle | null>(null);

  useEffect(() => {
    openP.value = withSpring(whenOpen ? 1 : 0, whenOpen ? openSpring : closeSpring);
  }, [whenOpen, openP]);

  useEffect(() => {
    const sub = Keyboard.addListener('keyboardWillChangeFrame', e => {
      // Visible keyboard height = window bottom − keyboard top (0 when the
      // keyboard parks below the screen on hide).
      const h = Math.max(0, Dimensions.get('window').height - e.endCoordinates.screenY);
      kbH.value = withTiming(h, {duration: e.duration || 250, easing: keyboardEasing});
    });
    return () => sub.remove();
  }, [kbH]);

  useEffect(
    () =>
      flowBus.on(type => {
        switch (type) {
          case 'barEnterSlide':
            // Glass content: transform-only spawn (Stage 57). 'pop' = the
            // native +40 rise with a 0.9→1 scale pop; 'clip' = rise from
            // behind the keyboard/bottom edge. The gradient fades as before.
            if (glassSpawn === 'pop') {
              entryY.value = entry.slideRise;
              contentScale.value = 0.9;
              contentScale.value = withSpring(1, entrySpring);
            } else {
              entryY.value = BAR_PARK;
            }
            entryY.value = withSpring(0, entrySpring);
            entryOpacity.value = withSpring(1, entrySpring);
            break;
          case 'barEnterMorph':
            // +280pt rise, no fade (the morph variant enters fully opaque).
            entryOpacity.value = 1;
            contentScale.value = 1;
            entryY.value = entry.morphRise;
            entryY.value = withSpring(0, entrySpring);
            break;
          case 'closing':
            // Gradient fades out (native); the glass content slides down
            // behind the keyboard on the same quick ease — alpha never
            // touches the glass (Stage 57).
            entryOpacity.value = withTiming(0, fadeOut120);
            entryY.value = withTiming(BAR_PARK, fadeOut120);
            break;
          case 'clearWhen':
            shellRef.current?.reset();
            break;
        }
      }),
    [contentScale, entryOpacity, entryY, flowBus, glassSpawn],
  );

  // The cluster root carries ONLY the keyboard ride + picker lift; the entry/
  // exit choreography is split (Stage 57): the gradient FADES (plain view),
  // the glass content moves by TRANSFORM only — its alpha never changes.
  const clusterStyle = useAnimatedStyle(() => {
    // When open, lift the cluster so the picker's top lands at pickerTopTarget
    // (symmetric gap to the header). Only lifts UP (never pushes below the
    // keyboard-anchored position); the freed space below is the white gradient.
    const pickerTopNow = screenH - kbH.value - bar.padBottom - openH.value;
    const lift =
      openH.value > 0 ? openP.value * Math.max(0, pickerTopNow - pickerTopTarget) : 0;
    return {
      transform: [{translateY: -kbH.value - lift}],
    };
  });
  const gradientStyle = useAnimatedStyle(() => ({opacity: entryOpacity.value}));
  const contentStyle = useAnimatedStyle(() => ({
    transform: [{translateY: entryY.value}, {scale: contentScale.value}],
  }));

  return (
    <Animated.View
      pointerEvents="box-none"
      style={[{position: 'absolute', left: 0, right: 0, bottom: 0}, clusterStyle]}>
      {/* White backdrop ramp behind the cluster (RedesignedScreen's gradient). */}
      <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, gradientStyle]}>
        <LinearGradient
          pointerEvents="none"
          colors={[
            'rgba(255,255,255,0)',
            'rgba(255,255,255,0.12)',
            'rgba(255,255,255,0.5)',
            'rgba(255,255,255,0.85)',
            color.white,
            color.white,
          ]}
          locations={[0, 0.095, 0.15, 0.21, bar.gradientSolidStop, 1]}
          style={StyleSheet.absoluteFill}
        />
      </Animated.View>
      {/* Tap-outside scrim over the gradient padding — closes the open picker;
          the shell renders on top and consumes its own touches. */}
      {whenOpen && (
        <Pressable style={StyleSheet.absoluteFill} onPress={() => onWhenOpenChange(false)} />
      )}
      <Animated.View
        pointerEvents="box-none"
        style={[
          {
            paddingHorizontal: bar.padH,
            paddingTop: bar.padTop,
            paddingBottom: bar.padBottom,
          },
          contentStyle,
        ]}>
        <MorphingShell
          whenOpen={whenOpen}
          onWhenOpenChange={onWhenOpenChange}
          onVoiceTap={onVoiceTap}
          voiceGlow={voiceGlow}
          onOpenHeight={h => {
            openH.value = h;
          }}
          shellRef={shellRef}
        />
      </Animated.View>
    </Animated.View>
  );
}
