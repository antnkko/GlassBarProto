import * as React from 'react';
import type {ViewProps} from 'react-native';

import NativeGlassEdge from './GlassEdgeNativeComponent';

export interface GlassEdgeProps extends ViewProps {
  edge: 'top' | 'bottom';
  appearance: 'light' | 'dark';
  /** Blur strength. */
  material: 'ultraThin' | 'thin' | 'regular' | 'thick';
  /** 0..0.8 — portion of the strip that stays fully blurred before fading. */
  fadeStart: number;
  /** Falloff gamma of the frost mask: 1 = linear fade, higher = steeper drop. */
  curve: number;
  /** 0..1 global multiplier. */
  intensity: number;
  /** Max radius (pt) of the real variable blur under the frost. */
  blurRadius: number;
  /** Falloff gamma of the blur ramp (smoothstep-eased, lands at zero). */
  blurCurve: number;
}

// Progressive edge blur strip (our own Material + gradient mask — see
// GlassEdgeBlurView.swift). Size/position it like any absolute view.
export default function GlassEdgeView(props: GlassEdgeProps) {
  return <NativeGlassEdge {...props} />;
}
