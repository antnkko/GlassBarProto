import {requireNativeView} from 'expo';
import * as React from 'react';

import type {GlassTabBarNativeProps} from './GlassTabBarView.types';

const NativeView = requireNativeView<GlassTabBarNativeProps>('GlassTabBar');

export default function GlassTabBarView(props: GlassTabBarNativeProps) {
  return <NativeView {...props} />;
}
