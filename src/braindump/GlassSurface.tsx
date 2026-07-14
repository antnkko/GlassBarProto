/**
 * Stage 41 — the RN counterpart of the native GlassButton/glassSurface recipe
 * (modules/glass-tab-bar/ios/Core/GlassButton.swift + GlassTabBarConfig).
 * Layer order, bottom → top, exactly as the native stack:
 *   1. Liquid Glass material (UIGlassEffect via @callstack/liquid-glass) —
 *      neutral: regular + white milk tint 0.95; accent: regular + accent tint.
 *   2. Frost fill INSIDE the glass, under content (white@0.9 / accent fill).
 *   3. Content.
 *   4. Ring overlay: 2pt at inset -1 (gray@0.13 neutral / accent@0.6).
 *   5. Drop shadow (#C1C3C6 0.35 / r14) — neutral only; accent casts none.
 * Continuous ("squircle") corners via borderCurve — the liquid-glass native
 * side mirrors cornerRadius+cornerCurve onto the effect view's layer.
 */
import React from 'react';
import {StyleSheet, View, ViewStyle, StyleProp} from 'react-native';
import {LiquidGlassView} from '@callstack/liquid-glass';
import Animated, {
  SharedValue,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from 'react-native-reanimated';
import type {AnimatedStyle} from 'react-native-reanimated';

import {color, glass} from './tokens';
import {
  decorHide,
  decorReturn,
  decorReturnDelay,
  ringShow,
  ringShowDelay,
  ringShowScaleFrom,
} from './motion';

export const AnimatedLiquidGlass = Animated.createAnimatedComponent(LiquidGlassView);

export type GlassDecor = {
  /** Ring visibility 0..1 (press-hide feedback). */
  ring: SharedValue<number>;
  /** Shadow visibility 0..1 (neutral surfaces only). */
  shadow: SharedValue<number>;
  onPressIn: () => void;
  onPressOut: () => void;
};

/**
 * The GlassButton press feedback: ring + shadow fade out while pressed
 * (easeInOut 0.12) and return after the release settles — shadow on
 * easeInOut 0.25 fired 180ms later, ring on the "Grow" show (easeOut 0.4,
 * +100ms, scale 0.94→1). Re-press cancels any pending return (an SV
 * assignment supersedes the delayed animation — the native token guard).
 */
export function useGlassDecorPress(): GlassDecor {
  const ring = useSharedValue(1);
  const shadow = useSharedValue(1);
  return {
    ring,
    shadow,
    onPressIn: () => {
      ring.value = withTiming(0, decorHide);
      shadow.value = withTiming(0, decorHide);
    },
    onPressOut: () => {
      shadow.value = withDelay(decorReturnDelay, withTiming(1, decorReturn));
      ring.value = withDelay(decorReturnDelay + ringShowDelay, withTiming(1, ringShow));
    },
  };
}

type Props = {
  kind?: 'neutral' | 'accent';
  /** Corner radius (continuous). Animate via `glassStyle` for morphs. */
  radius: number;
  /**
   * Native glass touch effect (press stretch/shimmer). OFF by default — the
   * braindump surfaces (shell, voice) use tap-only feedback per design;
   * mount-time only in the underlying UIGlassEffect.
   */
  interactive?: boolean;
  /** Outer container style — position/size the surface here. */
  style?: StyleProp<AnimatedStyle<ViewStyle>>;
  /** Animated style applied to BOTH the glass and the ring (e.g. borderRadius morph). */
  glassStyle?: StyleProp<AnimatedStyle<ViewStyle>>;
  /** Decor visibility from useGlassDecorPress (defaults to always-on). */
  decor?: Pick<GlassDecor, 'ring' | 'shadow'>;
  /**
   * Accent inner white glow (dev-panel tunable): `radius` = outer blur pt
   * (the native stack pairs it with a tighter 0.4× inner pass), `opacity` =
   * white alpha. Defaults match the frozen native look scaled up (Stage 42).
   */
  glow?: {radius: number; opacity: number};
  children?: React.ReactNode;
};

const defaultGlow = {radius: 16, opacity: 0.5};

export function GlassSurface({
  kind = 'neutral',
  radius,
  interactive = false,
  style,
  glassStyle,
  decor,
  glow,
  children,
}: Props) {
  const accent = kind === 'accent';
  const g = glow ?? defaultGlow;

  const shadowAnim = useAnimatedStyle(() => ({
    shadowOpacity: (decor ? decor.shadow.value : 1) * glass.shadowOpacity,
  }));
  const ringAnim = useAnimatedStyle(() => {
    const v = decor ? decor.ring.value : 1;
    return {
      opacity: v,
      transform: [{scale: ringShowScaleFrom + (1 - ringShowScaleFrom) * v}],
    };
  });

  return (
    <Animated.View
      style={[
        style,
        !accent && {
          shadowColor: glass.shadowColor,
          shadowRadius: glass.shadowRadius,
          shadowOffset: {width: 0, height: 0},
        },
        !accent && shadowAnim,
      ]}>
      <AnimatedLiquidGlass
        effect="regular"
        interactive={interactive}
        tintColor={accent ? color.vibrant : glass.milkTint}
        style={[
          StyleSheet.absoluteFill,
          {borderRadius: radius, borderCurve: 'continuous', overflow: 'hidden'},
          glassStyle,
        ]}>
        {accent ? (
          <>
            {/* Solid accent under the glass shimmer (native accentFill base). */}
            <View style={[StyleSheet.absoluteFill, {backgroundColor: color.vibrant}]} />
            {/* Inner glow — the native stacked inner shadows (tight 0.4×r +
                wide r), white at `glow.opacity`. Accent surfaces are
                static-radius (voice/✓), so no morph here. */}
            <View
              pointerEvents="none"
              style={[
                StyleSheet.absoluteFill,
                {
                  borderRadius: radius,
                  borderCurve: 'continuous',
                  boxShadow: `inset 0 0 ${Math.round(g.radius * 0.4)}px rgba(255,255,255,${g.opacity}), inset 0 0 ${Math.round(g.radius)}px rgba(255,255,255,${g.opacity})`,
                },
              ]}
            />
          </>
        ) : (
          /* Frost: matte white inside the glass, under content. */
          <View style={[StyleSheet.absoluteFill, {backgroundColor: glass.frostFill}]} />
        )}
        {children}
      </AnimatedLiquidGlass>
      {/* Ring: 2pt at inset -1 → outset the overlay by 1, radius +1. */}
      <Animated.View
        pointerEvents="none"
        style={[
          {
            position: 'absolute',
            top: -1,
            left: -1,
            right: -1,
            bottom: -1,
            borderWidth: glass.ringWidth,
            borderColor: accent ? glass.accentRingColor : glass.ringColor,
            borderRadius: radius + 1,
            borderCurve: 'continuous',
          },
          ringAnim,
        ]}
      />
    </Animated.View>
  );
}
