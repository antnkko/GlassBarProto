export const colors = {
  blazeOrange: '#F65D00', // blazeOrange/vibrant
  blazeOrangeLight: '#FFF2ED', // blazeOrange/light
  neutralMid: '#888A8E', // neutral/mid
  white: '#FFFFFF',
  ink: '#1B1D21',
} as const;

export const bar = {
  pillHeight: 62,
  bottomInsetExtra: 8,
  /** RN-side height of the native strip: pill + headroom for the interactive shimmer. */
  stripHeight: 78,
} as const;
