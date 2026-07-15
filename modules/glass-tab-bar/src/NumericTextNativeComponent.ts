import type {HostComponent, ViewProps} from 'react-native';
import type {Double} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/**
 * A leaf that renders a single line of text with SwiftUI's real
 * `.contentTransition(.numericText())` — Apple's per-glyph roll-and-blur when
 * the string changes. Sized by RN style (give it an explicit height; text
 * left-aligns and vertically centers in the frame).
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
}

export default codegenNativeComponent<NativeProps>(
  'NumericText',
) as HostComponent<NativeProps>;
