/**
 * Stage 41 — the braindump bottom-bar cluster tokens, mirrored 1:1 from the
 * native design system (ios/Numo/DesignSystem/Metrics.swift `Metrics.Redesign`
 * + Theme.swift NumoColor + GlassTabBarConfig.frozen()). Values are pt.
 */

export const color = {
  vibrant: '#F65D00',
  vibrantLight: '#FFB58A',
  skinLight: '#FFF2ED',
  white: '#FFFFFF',
  grayAlmost: '#F1F1F1',
  grayNormal: '#C1C3C6',
  grayNight: '#888A8E',
  neutralDark: '#4B4E52',
  ink: '#030303',
  highlight: '#DB7732',
} as const;

/** #RRGGBB → rgba() string (design tint fills/borders carry their own alpha). */
export function rgba(hex: string, alpha: number): string {
  const v = parseInt(hex.slice(1), 16);
  return `rgba(${(v >> 16) & 0xff},${(v >> 8) & 0xff},${v & 0xff},${alpha})`;
}

/** Obviously faces registered in UIAppFonts — PostScript name == basename. */
export const font = {
  medium: 'Obviously-Medium',
  semibold: 'Obviously-Semibold',
  narrowBold: 'ObviouslyNarrow-Bold',
} as const;

/** The frozen Liquid Glass recipe (GlassTabBarConfig.frozen()). */
export const glass = {
  /** In-material milk tint (Glass.tint white@0.95). */
  milkTint: 'rgba(255,255,255,0.95)',
  /** Frost fill layer INSIDE the glass, under content (white @ frost 0.9). */
  frostFill: 'rgba(255,255,255,0.9)',
  /** Neutral outer ring: 2pt, inset -1. */
  ringColor: 'rgba(193,195,198,0.13)',
  ringWidth: 2,
  /** Accent ring: 2pt accent @ 0.6. */
  accentRingColor: 'rgba(246,93,0,0.6)',
  /** Neutral drop shadow (accent surfaces cast none). */
  shadowColor: '#C1C3C6',
  shadowOpacity: 0.35,
  shadowRadius: 14,
} as const;

export const bar = {
  padH: 20,
  padTop: 40,
  padBottom: 20,
  gap: 16, // chip ↔ voice
  /** White backdrop gradient reaches solid at this fraction of its height. */
  gradientSolidStop: 0.27,
} as const;

export const shell = {
  radiusClosed: 20,
  radiusOpen: 24,
  heightClosed: 82,
} as const;

export const chip = {
  icon: 24,
  iconLabelGap: 4,
  dividerWidth: 2,
  dividerHeight: 32,
  labelSize: 16, // Obviously-Medium, ink
} as const;

export const voice = {
  width: 115,
  height: 80,
  radius: 20,
  barWidth: 4,
  barHeights: [12, 20, 16] as const,
  barGap: 4,
} as const;

export const row = {
  leading: 20,
  trailing: 20,
  padV: 14,
  gap: 12, // icon → text block
  icon: 28,
  labelSize: 14, // Obviously-Medium, grayNight
  valueSize: 17, // Obviously-Semibold, neutralDark
  textGap: -3, // label → value (Obviously line boxes are tall)
  chevron: 20,
  sepThickness: 2,
  sepOpacity: 0.5, // of grayAlmost
} as const;

export const strip = {
  pad: 12,
  cellHeight: 64,
  pillMaxWidth: 48,
  pillRadius: 14,
  pillBgOpacity: 0.15, // of vibrantLight
  weekdaySize: 12,
  weekdayTracking: 0.36,
  weekdayOpacity: 0.6, // unselected, of grayNight
  daySize: 17,
  todayDot: 6,
  todayDotOffset: 3,
} as const;

/** Segmented pill switch (SegmentedSwitch.swift SegSwitch, Figma 1112:8687). */
export const seg = {
  thumbHeight: 38,
  pad: 3, // → track height 44
  fontSize: 16,
  lineHeight: 22,
  textLift: 4, // optical centering (Figma chip pb-4)
  radius: 100,
  thumbShadowOpacity: 0.1,
  thumbShadowRadius: 5,
} as const;

/** Routine picker card (Figma 1122:11791 Routines, accents mapped to vibrant). */
export const routine = {
  switchPadH: 16,
  switchPadV: 20,
  bottomSwitchPadBottom: 18,
  stripPadH: 12,
  stripPadV: 14,
  tileW: 48,
  tileH: 64,
  tileRadius: 14,
  tileBorder: 2,
  tileBorderOpacity: 0.25, // of vibrantLight
  gridPadV: 8,
  gridRowPadH: 18,
  gridRowGap: 3,
  gridCell: 44,
  gridCellRadius: 14,
  gridDaySize: 16,
  gridDayTracking: -0.45,
  gridDayPadBottom: 3,
  repeatPadTop: 20,
  repeatPadBottom: 12,
  repeatPadLeft: 20,
  repeatGap: 6,
  repeatLabelSize: 17,
  /** Lifts the SwiftUI numeric value onto the RN label's baseline (the leaf
   *  centers its layout bounds; RN baselines within lineHeight differ). */
  repeatValueNudge: -2,
  dotSize: 6,
  dotOffset: 2,
} as const;

export const wheel = {
  rowHeight: 38,
  visibleRows: 5,
  colWidth: 44,
  colGap: 28,
  fontCenter: 18,
  fontFar: 14,
  opacityFar: 0.4,
  /** Rows-from-center at which the far look is fully reached (tuning knob). */
  rampRows: 1.2,
  bandOpacity: 0.15, // of vibrantLight
  minuteStep: 5,
  padV: 6,
} as const;

export const wheelHeight = wheel.rowHeight * wheel.visibleRows; // 190
export const wheelPadCenter = (wheel.rowHeight * (wheel.visibleRows - 1)) / 2; // 76

export const entry = {
  /** Morph entry: cluster rises from +280pt (no fade). */
  morphRise: 280,
  /** Slide-up entry: +28pt rise + fade-in — the exact mirror of the header's
   *  28pt landing drop (Stage 72b; was 40, which compounded with the still-
   *  rising keyboard into a visibly longer flight). */
  slideRise: 28,
} as const;
