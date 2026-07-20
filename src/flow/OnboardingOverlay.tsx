/**
 * Stage 53 — the onboarding overlay (OnboardingOverlay.swift 1:1): a white
 * gradient scrim (transparent over the brain dump up top, solid white by
 * ~61.5%) carrying the title + "See how" CTA. The parent owns the opacity
 * shared value (fade-in +120ms after the entrance; fade-out easeOut 180ms as
 * the morph's Act I begins) and the See-how handler (→ morphToRedesign).
 */
import React from 'react';
import {StyleSheet, Text, View} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import {LinearGradient} from 'expo-linear-gradient';
import Animated, {useAnimatedStyle, type SharedValue} from 'react-native-reanimated';

import {PressFade} from '../braindump/PressFade';
import {color, font} from '../braindump/tokens';
import {OverlayScrim} from './choreo';

type Props = {
  /** 0..1 — owned by the flow (reveal + Act-I fade-out timings). */
  opacity: SharedValue<number>;
  onSeeHow: () => void;
};

export function OnboardingOverlay({opacity, onSeeHow}: Props) {
  const insets = useSafeAreaInsets();
  const style = useAnimatedStyle(() => ({opacity: opacity.value}));
  return (
    <Animated.View style={[StyleSheet.absoluteFill, style]}>
      <LinearGradient
        colors={['rgba(255,255,255,0)', color.white]}
        locations={[OverlayScrim.transparentStop, OverlayScrim.solidStop]}
        style={StyleSheet.absoluteFill}
      />
      <View
        style={[styles.content, {paddingBottom: insets.bottom + 40}]}
        pointerEvents="box-none">
        <Text style={styles.title}>{'Dumping tasks\njust got better!'}</Text>
        <PressFade onPress={onSeeHow}>
          <View style={styles.cta}>
            <Text style={styles.ctaLabel}>See how</Text>
          </View>
        </PressFade>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  content: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'flex-end',
  },
  title: {
    textAlign: 'center',
    paddingHorizontal: 24,
    fontFamily: font.narrowBold,
    fontSize: 40,
    lineHeight: 46,
    letterSpacing: 0.8,
    color: color.ink,
  },
  cta: {
    marginTop: 36,
    marginHorizontal: 48,
    // Full pill whatever the actual label height (RN clamps to half-height).
    borderRadius: 999,
    borderCurve: 'continuous',
    backgroundColor: color.vibrant,
    alignItems: 'center',
    // Native lifts the Obviously label UP: text bottom pad 4+18, top 18.
    paddingTop: 18,
    paddingBottom: 22,
  },
  ctaLabel: {
    fontFamily: font.semibold,
    fontSize: 18,
    letterSpacing: 0.18,
    color: color.white,
  },
});
