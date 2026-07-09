import * as React from 'react';

import NativeGlassTabBar from './GlassTabBarNativeComponent';
import type {GlassTabBarNativeProps} from './GlassTabBarView.types';

// Bare Fabric component (codegen spec in GlassTabBarNativeComponent.ts).
// The public props contract lives in GlassTabBarView.types.ts; the spec
// mirrors it field-for-field, so a single cast bridges the two.
export default function GlassTabBarView(props: GlassTabBarNativeProps) {
  return <NativeGlassTabBar {...(props as React.ComponentProps<typeof NativeGlassTabBar>)} />;
}
