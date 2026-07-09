import * as React from 'react';
import type {ViewProps} from 'react-native';

import NativeGlassEdge from './GlassEdgeNativeComponent';

export interface GlassEdgeProps extends ViewProps {
  edge: 'top' | 'bottom';
  appearance: 'light' | 'dark';
}

// Progressive edge blur strip (our own Material + gradient mask — see
// GlassEdgeBlurView.swift). Size/position it like any absolute view.
export default function GlassEdgeView(props: GlassEdgeProps) {
  return <NativeGlassEdge {...props} />;
}
