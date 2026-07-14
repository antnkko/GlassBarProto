/**
 * Stage 41 — the vibrant voice-entry button (RN counterpart of VoiceButton.swift):
 * 115×80, radius 20 continuous, accent Liquid Glass with the white inner glow
 * and accent ring, three white voice-wave capsules. Press feedback = the
 * GlassButton decor hide (ring fades while pressed) + the glass's own
 * interactive shimmer.
 */
import React from 'react';
import {Pressable, StyleProp, View, ViewStyle} from 'react-native';

import {GlassSurface, useGlassDecorPress} from './GlassSurface';
import {color, voice} from './tokens';

type Props = {
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
};

export function VoiceButton({onPress, style}: Props) {
  const decor = useGlassDecorPress();
  return (
    <Pressable onPressIn={decor.onPressIn} onPressOut={decor.onPressOut} onPress={onPress}>
      <GlassSurface
        kind="accent"
        radius={voice.radius}
        decor={decor}
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
    </Pressable>
  );
}
