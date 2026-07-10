import {LinearGradient} from 'expo-linear-gradient';
import React from 'react';
import type {StyleProp, ViewStyle} from 'react-native';

// Edge scrim straight from the design (Figma iOS-27, node 320:2512):
// a 16-stop eased white gradient, solid 0.9 at the screen edge easing to
// transparent toward the content. Replaces the whole native blur stack —
// a plain gradient never touches the glass pills' backdrop sampling.
const STOPS: Array<[location: number, alpha: number]> = [
  [0, 0],
  [0.1179, 0.066],
  [0.21384, 0.138],
  [0.2912, 0.215],
  [0.35336, 0.293],
  [0.4037, 0.373],
  [0.4456, 0.453],
  [0.48243, 0.531],
  [0.51757, 0.605],
  [0.5544, 0.674],
  [0.5963, 0.737],
  [0.64664, 0.791],
  [0.7088, 0.837],
  [0.78616, 0.871],
  [0.8821, 0.892],
  [1, 0.9],
];

function rampFor(edge: 'top' | 'bottom', dark: boolean) {
  // The design gradient runs transparent -> 0.9 downward (bottom edge).
  // For the top edge the ramp is mirrored so 0.9 sits at the screen edge.
  const base = dark ? '18, 19, 22' : '255, 255, 255';
  const stops = edge === 'top' ? [...STOPS].reverse() : STOPS;
  return {
    colors: stops.map(([, alpha]) => `rgba(${base}, ${alpha})`) as [string, string, ...string[]],
    locations: (edge === 'top'
      ? stops.map(([location]) => 1 - location)
      : stops.map(([location]) => location)) as [number, number, ...number[]],
  };
}

interface Props {
  edge: 'top' | 'bottom';
  dark?: boolean;
  style?: StyleProp<ViewStyle>;
}

export default function EdgeScrim({edge, dark = false, style}: Props) {
  const {colors, locations} = rampFor(edge, dark);
  return <LinearGradient colors={colors} locations={locations} style={style} pointerEvents="none" />;
}
