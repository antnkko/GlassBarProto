import * as React from 'react';

import NativeGlassToolbar from './GlassToolbarNativeComponent';
import type {GlassToolbarNativeProps} from './GlassToolbarView.types';

// Bare Fabric component (codegen spec in GlassToolbarNativeComponent.ts).
export default function GlassToolbarView(props: GlassToolbarNativeProps) {
  return <NativeGlassToolbar {...(props as React.ComponentProps<typeof NativeGlassToolbar>)} />;
}
