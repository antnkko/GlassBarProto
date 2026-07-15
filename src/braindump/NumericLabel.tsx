/**
 * Stage 45 — a drop-in for RollingText backed by SwiftUI's real
 * `.contentTransition(.numericText())` (NumericText Fabric leaf): Apple's
 * per-glyph roll + blur on string change, 1:1. Sized by an explicit height
 * (the text left-aligns and vertically centers in the frame).
 */
import React from 'react';
import {NumericTextView} from '../../modules/glass-tab-bar';

type Props = {
  text: string;
  fontSize: number;
  fontFamily: string;
  color: string; // #RRGGBB
  tracking?: number;
  /** Line box height — give it the value line height so the roll has room. */
  height: number;
};

export function NumericLabel({text, fontSize, fontFamily, color, tracking = 0, height}: Props) {
  // No explicit width — a column child stretches to the parent (the flex value
  // cell); the SwiftUI text left-aligns inside.
  return (
    <NumericTextView
      text={text}
      fontSize={fontSize}
      fontFamily={fontFamily}
      colorHex={color}
      tracking={tracking}
      style={{height, alignSelf: 'stretch'}}
    />
  );
}
