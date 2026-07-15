/**
 * Stage 45/47 — SwiftUI-backed text stack: optional small label over a value
 * that changes through the real `.contentTransition(.numericText())` (Apple's
 * per-glyph roll + blur). Both lines render in ONE SwiftUI VStack (native
 * rowTextGap spacing) so their relative position is metric-exact — an RN Text
 * label above the SwiftUI value never aligned reliably. Sized by an explicit
 * height; the stack left-aligns and vertically centers in the frame.
 */
import React from 'react';
import {NumericTextView} from '../../modules/glass-tab-bar';

type Props = {
  text: string;
  fontSize: number;
  fontFamily: string;
  color: string; // #RRGGBB
  tracking?: number;
  /** Optional label line above the value ('' = value only). */
  label?: string;
  labelFontSize?: number;
  labelFontFamily?: string;
  labelColor?: string; // #RRGGBB
  /** VStack spacing label→value (native rowTextGap = -3). */
  textGap?: number;
  /** Line-box height (two lines when label is set). */
  height: number;
};

export function NumericLabel({
  text,
  fontSize,
  fontFamily,
  color,
  tracking = 0,
  label = '',
  labelFontSize = 14,
  labelFontFamily = 'Obviously-Medium',
  labelColor = '#888A8E',
  textGap = -3,
  height,
}: Props) {
  return (
    <NumericTextView
      text={text}
      fontSize={fontSize}
      fontFamily={fontFamily}
      colorHex={color}
      tracking={tracking}
      label={label}
      labelFontSize={labelFontSize}
      labelFontFamily={labelFontFamily}
      labelColorHex={labelColor}
      textGap={textGap}
      style={{height, alignSelf: 'stretch'}}
    />
  );
}
