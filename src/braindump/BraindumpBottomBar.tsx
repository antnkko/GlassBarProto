/**
 * Stage 41 — the RN-owned braindump bottom-bar cluster, rendered as a sibling
 * ABOVE the transparent NumoFlow overlay. Owns: keyboard riding (RN Keyboard
 * events fire for the native TextField's keyboard), the entry/exit beats
 * (played on events emitted by the native timelines), the white backdrop
 * gradient and the tap-outside scrim. The morphing shell + picker + voice
 * live in MorphingShell.
 */
import React, {useEffect, useRef} from 'react';
import {Dimensions, Keyboard, Pressable, StyleSheet, View} from 'react-native';
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
import {entrySpring, fadeOut120, keyboardEasing} from './motion';

type Props = {
  whenOpen: boolean;
  onWhenOpenChange: (open: boolean) => void;
  flowBus: FlowBus;
  /** Voice button inner glow (dev-panel tunable). */
  voiceGlow?: {radius: number; opacity: number};
  onVoiceTap?: () => void;
};

export function BraindumpBottomBar({
  whenOpen,
  onWhenOpenChange,
  flowBus,
  voiceGlow,
  onVoiceTap,
}: Props) {
  // Keyboard top — the cluster sits right above it (the native bar used the
  // bottom safe-area inset, which the keyboard replaces wholesale).
  const kbH = useSharedValue(0);
  // Entry/exit choreography (native MorphChoreo beats, event-driven).
  const entryY = useSharedValue<number>(entry.slideRise);
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

  useEffect(
    () =>
      flowBus.on(type => {
        switch (type) {
          case 'barEnterSlide':
            // +40pt rise + fade-in, both on the entry spring (native applies
            // one withAnimation to opacity and offset together).
            entryY.value = entry.slideRise;
            entryY.value = withSpring(0, entrySpring);
            entryOpacity.value = withSpring(1, entrySpring);
            break;
          case 'barEnterMorph':
            // +280pt rise, no fade (the morph variant enters fully opaque).
            entryOpacity.value = 1;
            entryY.value = entry.morphRise;
            entryY.value = withSpring(0, entrySpring);
            break;
          case 'closing':
            entryOpacity.value = withTiming(0, fadeOut120);
            break;
          case 'clearWhen':
            shellRef.current?.reset();
            break;
        }
      }),
    [entryOpacity, entryY, flowBus],
  );

  const clusterStyle = useAnimatedStyle(() => ({
    opacity: entryOpacity.value,
    transform: [{translateY: -kbH.value + entryY.value}],
  }));

  return (
    <Animated.View
      pointerEvents="box-none"
      style={[{position: 'absolute', left: 0, right: 0, bottom: 0}, clusterStyle]}>
      {/* White backdrop ramp behind the cluster (RedesignedScreen's gradient). */}
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
      {/* Tap-outside scrim over the gradient padding — closes the open picker;
          the shell renders on top and consumes its own touches. */}
      {whenOpen && (
        <Pressable style={StyleSheet.absoluteFill} onPress={() => onWhenOpenChange(false)} />
      )}
      <View
        pointerEvents="box-none"
        style={{
          paddingHorizontal: bar.padH,
          paddingTop: bar.padTop,
          paddingBottom: bar.padBottom,
        }}>
        <MorphingShell
          whenOpen={whenOpen}
          onWhenOpenChange={onWhenOpenChange}
          onVoiceTap={onVoiceTap}
          voiceGlow={voiceGlow}
          shellRef={shellRef}
        />
      </View>
    </Animated.View>
  );
}
