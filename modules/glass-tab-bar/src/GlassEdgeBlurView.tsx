import * as React from 'react';
import type {ViewProps} from 'react-native';

import NativeGlassEdgeBlur from './GlassEdgeBlurNativeComponent';

export interface GlassEdgeBlurProps extends ViewProps {
  edge: 'top' | 'bottom';
  /** Blur radius (pt) at the dense end; 0 disables the stack visually. */
  maxRadius: number;
  /** Master-curve exponent shared with the scrim's smoothness. */
  smoothness: number;
}

// Progressive gaussian-stack blur (see ProgressiveBlurStackView.swift).
export default function GlassEdgeBlurView(props: GlassEdgeBlurProps) {
  return <NativeGlassEdgeBlur {...props} />;
}
