/**
 * Stage 44 — the RN counterpart of SwiftUI's `.contentTransition(.numericText())`
 * (the DumpedScreen/VoiceDump confirmation title): when the string changes,
 * only the CHANGED characters animate — the old glyph rolls up and fades out,
 * the new one bounces in from below on the donor spring (response 0.4 /
 * dampingFraction 0.6 → {246.74, 18.85}).
 *
 * Mechanism: one Animated.Text per character, keyed by position+char.
 * Unchanged characters keep their key → no animation; a changed character
 * swaps its key → Reanimated exiting/entering layout animations run the roll.
 */
import React from 'react';
import {StyleProp, TextStyle, View} from 'react-native';
import Animated, {withSpring, withTiming} from 'react-native-reanimated';
import type {EntryExitAnimationFunction} from 'react-native-reanimated';

import {fadeOut160, numericSpring} from './motion';

type Props = {
  text: string;
  /** Font size drives the roll distance (~0.55em, like the native digit roll). */
  fontSize: number;
  style?: StyleProp<TextStyle>;
};

function makeRollIn(distance: number): EntryExitAnimationFunction {
  return () => {
    'worklet';
    return {
      initialValues: {opacity: 0, transform: [{translateY: distance}]},
      animations: {
        opacity: withSpring(1, numericSpring),
        transform: [{translateY: withSpring(0, numericSpring)}],
      },
    };
  };
}

function makeRollOut(distance: number): EntryExitAnimationFunction {
  return () => {
    'worklet';
    return {
      initialValues: {opacity: 1, transform: [{translateY: 0}]},
      animations: {
        // The outgoing glyph leads out fast (the native roll's old digit is
        // gone quickly while the new one is still bouncing).
        opacity: withTiming(0, fadeOut160),
        transform: [{translateY: withTiming(-distance, fadeOut160)}],
      },
    };
  };
}

export function RollingText({text, fontSize, style}: Props) {
  const distance = Math.round(fontSize * 0.55);
  const rollIn = React.useMemo(() => makeRollIn(distance), [distance]);
  const rollOut = React.useMemo(() => makeRollOut(distance), [distance]);
  return (
    <View style={{flexDirection: 'row'}}>
      {text.split('').map((ch, i) => (
        <Animated.Text
          key={`${i}:${ch}`}
          entering={rollIn}
          exiting={rollOut}
          style={[{fontSize}, style]}>
          {ch === ' ' ? ' ' : ch}
        </Animated.Text>
      ))}
    </View>
  );
}
