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

const MAX_ALPHA = 0.9;
const SAMPLES = 64;

// Piecewise-linear read of the design curve (alpha at a given location).
function sampleDesign(location: number): number {
  let prev = STOPS[0];
  for (const stop of STOPS.slice(1)) {
    if (location <= stop[0]) {
      const span = stop[0] - prev[0];
      if (span <= 0) {
        return stop[1];
      }
      const f = (location - prev[0]) / span;
      return prev[1] + (stop[1] - prev[1]) * f;
    }
    prev = stop;
  }
  return MAX_ALPHA;
}

function rampFor(edge: 'top' | 'bottom', dark: boolean, smoothness: number) {
  // The design gradient runs transparent -> 0.9 downward (bottom edge);
  // the top edge mirrors it so 0.9 sits at the screen edge.
  //
  // The 16 design stops are RESAMPLED into 64: CAGradientLayer interpolates
  // linearly between stops, and with only 16 the slope kinks read as Mach
  // bands — the visible "start" of the gradient. Dense sampling puts the
  // polyline error below perception. Smoothness then raises the normalized
  // alphas to a power, flattening the transparent tail to a zero-slope
  // landing. 1 = design curve.
  const base = dark ? '18, 19, 22' : '255, 255, 255';
  const power = Math.max(1, smoothness);
  const colors: string[] = [];
  const locations: number[] = [];
  for (let i = 0; i < SAMPLES; i++) {
    const position = i / (SAMPLES - 1);
    const designLocation = edge === 'top' ? 1 - position : position;
    const alpha = MAX_ALPHA * Math.pow(sampleDesign(designLocation) / MAX_ALPHA, power);
    colors.push(`rgba(${base}, ${Number(alpha.toFixed(4))})`);
    locations.push(position);
  }
  return {
    colors: colors as [string, string, ...string[]],
    locations: locations as [number, number, ...number[]],
  };
}

interface Props {
  edge: 'top' | 'bottom';
  dark?: boolean;
  /** 1 = design curve; higher flattens the transparent tail (softer onset). */
  smoothness?: number;
  style?: StyleProp<ViewStyle>;
}

export default function EdgeScrim({edge, dark = false, smoothness = 1, style}: Props) {
  const {colors, locations} = rampFor(edge, dark, smoothness);
  return <LinearGradient colors={colors} locations={locations} style={style} pointerEvents="none" />;
}
