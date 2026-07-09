import type {HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';
import type {Double} from 'react-native/Libraries/Types/CodegenTypes';

// Our own progressive edge blur: a SwiftUI Material masked by an eased
// gradient. Replaces the system UIScrollEdgeEffect stack, whose blur region
// proved uncontrollable from an RN layout (it follows the safe area only).
export interface NativeProps extends ViewProps {
  /** Which screen edge the blur fades from: 'top' | 'bottom'. */
  edge: string;
  /** 'light' | 'dark' — pins the material's appearance. */
  appearance: string;
  /** Blur strength: 'ultraThin' | 'thin' | 'regular' | 'thick'. */
  material: string;
  /** 0..0.8 — portion of the strip that stays fully blurred before fading. */
  fadeStart: Double;
  /** Falloff gamma: 1 = linear fade, higher = steeper drop. */
  curve: Double;
  /** 0..1 global multiplier on the whole strip. */
  intensity: Double;
}

export default codegenNativeComponent<NativeProps>(
  'GlassEdge',
) as HostComponent<NativeProps>;
