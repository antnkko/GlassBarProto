import type {HostComponent, ViewProps} from 'react-native';
import type {Double} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/**
 * A leaf that renders a (label +) value text stack with SwiftUI's real
 * `.contentTransition(.numericText())` on the value — Apple's per-glyph
 * roll-and-blur when the string changes. BOTH lines live in ONE SwiftUI
 * VStack so their relative position uses a single font-metric system (mixing
 * an RN Text label with a SwiftUI value never aligned reliably — Stage 47).
 * Sized by RN style (explicit height; the stack left-aligns and vertically
 * centers in the frame).
 */
export interface NativeProps extends ViewProps {
  text: string;
  fontSize: Double;
  /** PostScript/family name (registered in UIAppFonts), e.g. Obviously-Semibold. */
  fontFamily: string;
  /** #RRGGBB. */
  colorHex: string;
  /** Letter spacing (pt). */
  tracking: Double;
  /** Optional small label ABOVE the value ('' = value only). */
  label: string;
  labelFontSize: Double;
  labelFontFamily: string;
  /** #RRGGBB. */
  labelColorHex: string;
  /** VStack spacing label→value (native rowTextGap = -3). */
  textGap: Double;
}

export default codegenNativeComponent<NativeProps>(
  'NumericText',
) as HostComponent<NativeProps>;
