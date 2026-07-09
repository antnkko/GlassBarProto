import {requireNativeView} from 'expo';
import * as React from 'react';

import type {GlassToolbarNativeProps} from './GlassToolbarView.types';

// Second (named) view of the GlassTabBar module — SwiftUI views register
// under their Swift class name.
const NativeView = requireNativeView<GlassToolbarNativeProps>('GlassTabBar', 'GlassToolbarExpoView');

export default function GlassToolbarView(props: GlassToolbarNativeProps) {
  return <NativeView {...props} />;
}
