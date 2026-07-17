/**
 * Stage 41 — the RN-owned braindump bottom-bar cluster, rendered as a sibling
 * ABOVE the transparent NumoFlow overlay. Owns: keyboard riding (RN Keyboard
 * events fire for the native TextField's keyboard), the entry/exit beats
 * (played on events emitted by the native timelines), the white backdrop
 * gradient and the tap-outside scrim. The morphing shell + picker + voice
 * live in MorphingShell.
 */
import React, {useCallback, useEffect, useRef} from 'react';
import {Dimensions, Keyboard, Pressable, StyleSheet} from 'react-native';
import {LinearGradient} from 'expo-linear-gradient';
import Animated, {
  runOnUI,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';

import {FlowBus} from './flowEvents';
import {MorphingShell, MorphingShellHandle, PickerKind} from './MorphingShell';
import {bar, color, entry} from './tokens';
import {entrySpring, fadeOut120, keyboardEasing} from './motion';

/** Stage 57/58 'clip' hide distance: the unveil window starts fully below the
 *  content (content ≈142 + shadow bleed). */
const BAR_PARK = 180;

/** Entry/exit beats driven by the flow on the UI thread (Stage 58 — the JS
 *  setTimeout→flowBus path drifted and made the open read jerky). */
export const BAR_BEAT = {idle: 0, enterSlide: 1, enterMorph: 2, closing: 3, reset: 4} as const;

type Props = {
  openPicker: PickerKind;
  onOpenPickerChange: (picker: PickerKind) => void;
  flowBus: FlowBus;
  /** Voice button inner glow (dev-panel tunable). */
  voiceGlow?: {radius: number; opacity: number};
  /** Stage 57: transform-only spawn for the glass content (alpha over
   *  UIGlassEffect renders broken/black on device); the white gradient
   *  backdrop still fades — it's a plain RN view. */
  glassSpawn?: 'clip' | 'pop';
  /** Stage 58: UI-thread beat channel (BAR_BEAT values) — the RN flow drives
   *  entries/exits with withDelay on the UI thread (JS timers drifted and the
   *  bar arrived late). Absent on the native path (flowBus events drive it). */
  beat?: SharedValue<number>;
  onVoiceTap?: () => void;
};

export function BraindumpBottomBar({
  openPicker,
  onOpenPickerChange,
  flowBus,
  voiceGlow,
  glassSpawn = 'clip',
  beat,
  onVoiceTap,
}: Props) {
  const pickerShown = openPicker !== 'none';
  // Keyboard top — the cluster sits right above it (the native bar used the
  // bottom safe-area inset, which the keyboard replaces wholesale).
  const kbH = useSharedValue(0);
  // Stage 58 stationary-glass unveil ('clip'): the glass content sits at its
  // FINAL position from mount (the material samples its real backdrop and is
  // fully adapted at reveal — moving/fading it caused the boosted-shadow
  // artifact); a clip WINDOW translated by `unveilV` (content counter −v)
  // hides/reveals it. `entryY` moves the content itself only where native
  // does (the morph's +280 rise, the 'pop' drop). Scale never hits 0
  // (degenerate matrices break hosted native rendering).
  const unveilV = useSharedValue(glassSpawn === 'clip' ? BAR_PARK : 0);
  const entryY = useSharedValue<number>(glassSpawn === 'pop' ? BAR_PARK : 0);
  const contentScale = useSharedValue(1);
  // The gradient backdrop's fade (plain RN view — alpha is safe here).
  const entryOpacity = useSharedValue(0);

  const shellRef = useRef<MorphingShellHandle | null>(null);

  useEffect(() => {
    const sub = Keyboard.addListener('keyboardWillChangeFrame', e => {
      // Visible keyboard height = window bottom − keyboard top (0 when the
      // keyboard parks below the screen on hide).
      const h = Math.max(0, Dimensions.get('window').height - e.endCoordinates.screenY);
      kbH.value = withTiming(h, {duration: e.duration || 250, easing: keyboardEasing});
    });
    return () => sub.remove();
  }, [kbH]);

  // ONE beat implementation, worklet-callable: the RN flow drives it on the
  // UI thread (beat channel, zero JS latency); the native path reaches it
  // from the flowBus events via runOnUI.
  const runBeat = useCallback(
    (b: number) => {
      'worklet';

      if (b === BAR_BEAT.enterSlide) {
        if (glassSpawn === 'pop') {
          // Native +40 rise with a 0.9→1 scale pop (content really moves).
          entryY.value = entry.slideRise;
          contentScale.value = 0.9;
          contentScale.value = withSpring(1, entrySpring);
          entryY.value = withSpring(0, entrySpring);
        } else {
          // Stationary-glass unveil: only the clip window moves.
          unveilV.value = withSpring(0, entrySpring);
        }
        entryOpacity.value = withSpring(1, entrySpring);
      } else if (b === BAR_BEAT.enterMorph) {
        // +280pt rise, no fade (native-defined; emerges from behind the
        // keyboard edge — the clip window sits open in 'clip' mode).
        entryOpacity.value = 1;
        contentScale.value = 1;
        unveilV.value = 0;
        entryY.value = entry.morphRise;
        entryY.value = withSpring(0, entrySpring);
      } else if (b === BAR_BEAT.reset) {
        // Instant park (persistent flow re-arm): hidden, no animation.
        entryOpacity.value = 0;
        contentScale.value = 1;
        unveilV.value = glassSpawn === 'clip' ? BAR_PARK : 0;
        entryY.value = glassSpawn === 'pop' ? BAR_PARK : 0;
      } else if (b === BAR_BEAT.closing) {
        // Gradient fades (native); the glass hides via the reverse unveil
        // ('clip') / slide-down ('pop') — alpha never touches the glass.
        entryOpacity.value = withTiming(0, fadeOut120);
        if (glassSpawn === 'pop') {
          entryY.value = withTiming(BAR_PARK, fadeOut120);
        } else {
          unveilV.value = withTiming(BAR_PARK, fadeOut120);
        }
      }
    },
    [contentScale, entryOpacity, entryY, glassSpawn, unveilV],
  );

  // UI-thread beat channel (RN flow).
  useAnimatedReaction(
    () => (beat ? beat.value : 0),
    (b, prev) => {
      if (b !== prev && b !== BAR_BEAT.idle) {
        runBeat(b);
      }
    },
    [runBeat],
  );

  // JS event path (native flow) + non-visual intents.
  useEffect(
    () =>
      flowBus.on(type => {
        switch (type) {
          case 'barEnterSlide':
            runOnUI(runBeat)(BAR_BEAT.enterSlide);
            break;
          case 'barEnterMorph':
            runOnUI(runBeat)(BAR_BEAT.enterMorph);
            break;
          case 'closing':
            runOnUI(runBeat)(BAR_BEAT.closing);
            break;
          case 'clearWhen':
            shellRef.current?.reset();
            break;
        }
      }),
    [flowBus, runBeat],
  );

  // Bottom sheet: the cluster (and any open picker) sits flush above the
  // keyboard — no lift toward the header (main's design decision). The entry/
  // exit choreography is split (Stage 57): the gradient FADES (plain view),
  // the glass content moves by TRANSFORM only — its alpha never changes.
  const clusterStyle = useAnimatedStyle(() => ({
    transform: [{translateY: -kbH.value}],
  }));
  const gradientStyle = useAnimatedStyle(() => ({opacity: entryOpacity.value}));
  // The unveil pair: window +v / content −v cancel out, so the glass layer is
  // screen-stationary while the moving clip edge reveals it.
  const windowStyle = useAnimatedStyle(() => ({
    transform: [{translateY: unveilV.value}],
  }));
  const contentStyle = useAnimatedStyle(() => ({
    transform: [
      {translateY: -unveilV.value + entryY.value},
      {scale: contentScale.value},
    ],
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
      {pickerShown && (
        <Pressable style={StyleSheet.absoluteFill} onPress={() => onOpenPickerChange('none')} />
      )}
      {/* Clip window ('clip' spawn): translated by +unveilV while the content
          counters with −unveilV — the glass never moves during the unveil. */}
      <Animated.View
        pointerEvents="box-none"
        style={[glassSpawn === 'clip' && styles.unveilWindow, windowStyle]}>
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
            openPicker={openPicker}
            onOpenPickerChange={onOpenPickerChange}
            onVoiceTap={onVoiceTap}
            voiceGlow={voiceGlow}
            shellRef={shellRef}
          />
        </Animated.View>
      </Animated.View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  unveilWindow: {overflow: 'hidden'},
});
