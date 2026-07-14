/**
 * Stage 41 — the native PressFadeStyle for inner tappables (chip zones, rows,
 * week cells): scale 0.96 + opacity 0.85 on a response-0.3/df-0.66 spring.
 */
import React from 'react';
import {Pressable, StyleProp, ViewStyle} from 'react-native';
import Animated, {useAnimatedStyle, useSharedValue, withSpring} from 'react-native-reanimated';

import {pressSpring} from './motion';

type Props = {
  onPress?: () => void;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  children: React.ReactNode;
};

export function PressFade({onPress, disabled, style, children}: Props) {
  const pressed = useSharedValue(0);
  const anim = useAnimatedStyle(() => ({
    opacity: 1 - 0.15 * pressed.value,
    transform: [{scale: 1 - 0.04 * pressed.value}],
  }));
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      onPressIn={() => (pressed.value = withSpring(1, pressSpring))}
      onPressOut={() => (pressed.value = withSpring(0, pressSpring))}
      style={style}>
      <Animated.View style={[{flex: 1}, anim]}>{children}</Animated.View>
    </Pressable>
  );
}
