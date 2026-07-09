import type {HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';

// Our own progressive edge blur: a SwiftUI Material masked by an eased
// gradient. Replaces the system UIScrollEdgeEffect stack, whose blur region
// proved uncontrollable from an RN layout (it follows the safe area only).
export interface NativeProps extends ViewProps {
  /** Which screen edge the blur fades from: 'top' | 'bottom'. */
  edge: string;
  /** 'light' | 'dark' — pins the material's appearance. */
  appearance: string;
}

export default codegenNativeComponent<NativeProps>(
  'GlassEdge',
) as HostComponent<NativeProps>;
