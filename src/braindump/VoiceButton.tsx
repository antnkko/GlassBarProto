/**
 * Stage 41/42 — the vibrant voice-entry button (RN counterpart of
 * VoiceButton.swift): 115×80, radius 20 continuous, accent Liquid Glass with
 * the white inner glow and accent ring, three white voice-wave capsules.
 * Stage 42: NO glass stretch (interactive off per design) — tap-only
 * feedback: the PressFade dip (scale 0.96 / opacity 0.85) + ring hide.
 */
import React from 'react';
import {Pressable, StyleProp, View, ViewStyle} from 'react-native';
import Animated, {useAnimatedStyle, useSharedValue, withSpring} from 'react-native-reanimated';

import {GlassSurface, useGlassDecorPress} from './GlassSurface';
import {pressSpring} from './motion';
import {color, voice} from './tokens';

type Props = {
  onPress?: () => void;
  /** Inner white glow (dev-panel tunable): blur radius pt + alpha. */
  glow?: {radius: number; opacity: number};
  style?: StyleProp<ViewStyle>;
};

export function VoiceButton({onPress, glow, style}: Props) {
  const decor = useGlassDecorPress();
  const pressed = useSharedValue(0);
  const dip = useAnimatedStyle(() => ({
    opacity: 1 - 0.15 * pressed.value,
    transform: [{scale: 1 - 0.04 * pressed.value}],
  }));
  return (
    <Pressable
      onPressIn={() => {
        pressed.value = withSpring(1, pressSpring);
        decor.onPressIn();
      }}
      onPressOut={() => {
        pressed.value = withSpring(0, pressSpring);
        decor.onPressOut();
      }}
      onPress={onPress}>
      <Animated.View style={dip}>
        <GlassSurface
          kind="accent"
          radius={voice.radius}
          decor={decor}
          glow={glow}
          style={[{width: voice.width, height: voice.height}, style]}>
        <View
          style={{
            flex: 1,
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'center',
            gap: voice.barGap,
          }}>
          {voice.barHeights.map((h, i) => (
            <View
              key={i}
              style={{
                width: voice.barWidth,
                height: h,
                borderRadius: voice.barWidth / 2,
                backgroundColor: color.white,
              }}
            />
          ))}
          </View>
        </GlassSurface>
      </Animated.View>
    </Pressable>
  );
}
