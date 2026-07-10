import type {HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';
import type {Double} from 'react-native/Libraries/Types/CodegenTypes';

// Seamless progressive blur strip: a native stack of fixed-radius gaussian
// blur layers crossfading in log-radius space (no mip stepping, invisible
// onset). Pairs with the RN EdgeScrim tint above it.
export interface NativeProps extends ViewProps {
  /** Which screen edge the blur hugs: 'top' | 'bottom'. */
  edge: string;
  /** Blur radius (pt) at the dense end of the strip. */
  maxRadius: Double;
  /** Shared master-curve exponent (same knob as the scrim's smoothness). */
  smoothness: Double;
}

export default codegenNativeComponent<NativeProps>(
  'GlassEdgeBlur',
) as HostComponent<NativeProps>;
