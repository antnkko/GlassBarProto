import type {
  BarAppearance,
  GlassConfig,
  HighlightBlend,
  ToolbarOption,
} from '../../modules/glass-tab-bar';

export type ThemeName = 'blazeOrange' | 'blueRibbon' | 'jade' | 'slack';

export interface ThemePalette {
  /** vibrant — active icon, plus button */
  accent: string;
  /** light — active highlight fill (light appearance) */
  light: string;
  /** dimmed accent tone for the highlight on dark glass */
  darkLight: string;
  /** mid — inactive icons */
  mid: string;
}

/** Numo palettes, pulled from the Figma OKLCH-Themes library ("— new" frames). */
export const THEMES: Record<ThemeName, ThemePalette> = {
  blazeOrange: {accent: '#F65D00', light: '#FFF2ED', darkLight: '#382312', mid: '#888A8E'},
  blueRibbon: {accent: '#0468FF', light: '#EFF6FF', darkLight: '#12253C', mid: '#888A8E'},
  jade: {accent: '#02AC42', light: '#EFF8EF', darkLight: '#102B1D', mid: '#878B87'},
  slack: {accent: '#7636A2', light: '#F8F3FD', darkLight: '#2A1C3E', mid: '#8B898E'},
};

/** Panel state: theme + material + motion + scrim. Layout values are frozen. */
export interface AppConfig {
  theme: ThemeName;
  milkOpacity: number;
  highlightBlend: HighlightBlend;
  highlightOpacity: number;
  appearance: BarAppearance;

  containerSpacing: number;

  springDuration: number;
  springBounce: number;

  edgeBlur: boolean;

  /** Figma toolbar dev-spec configuration (1–8), 0 = no toolbar. */
  toolbarOption: ToolbarOption;

  /** Height of the top design scrim (full height from the screen edge). */
  toolbarEdgeHeight: number;
  /** Height of the bottom design scrim (full height from the screen edge). */
  scrimBottomHeight: number;
  /** 1 = design curve; higher flattens the scrim's transparent tail. */
  scrimSmoothness: number;
  /** Max radius (pt) of the top progressive blur stack; 0 = gradient only. */
  edgeBlurMax: number;
  glassInteractive: boolean;
  /** Extra frost inside the glass (mattes + hides rim glints). Fresh key
   *  (was `frost`) so the 0.9 default lands over stored configs. */
  frostLevel: number;
}

export const defaultConfig: AppConfig = {
  theme: 'blazeOrange',
  milkOpacity: 0.95,
  // Figma: the active highlight is mix-blend-multiply, not a flat fill.
  highlightBlend: 'multiply',
  highlightOpacity: 1,
  appearance: 'light',

  containerSpacing: 0,

  springDuration: 0.44,
  springBounce: 0.22,

  edgeBlur: true,

  toolbarOption: 2,
  // Scrim heights from the design (Figma 320:2512): top 356, bottom 114.
  // scrimBottomHeight is a fresh key so it merges over stored configs.
  toolbarEdgeHeight: 280,
  scrimBottomHeight: 160,
  scrimSmoothness: 3,
  edgeBlurMax: 0,
  glassInteractive: true,
  frostLevel: 0.9,
};

/** Frozen Figma layout values — no UI controls, live only here. */
const frozenLayout = {
  pillWidth: 80,
  pillHeight: 62,
  innerPadding: 4,
  gap: 16,
  hPadding: 24,
  subTabSpacing: 0,
  iconSize: 32,
  plusIconSize: 28,
} as const;

/** Resolve the panel state into the native GlassConfig record. */
export function toNativeConfig(config: AppConfig): GlassConfig {
  const palette = THEMES[config.theme] ?? THEMES.blazeOrange;
  return {
    milkOpacity: config.milkOpacity,
    accentHex: palette.accent,
    // On dark glass the light pastel reads as a white blob — use the dimmed accent tone.
    lightHex: config.appearance === 'dark' ? palette.darkLight : palette.light,
    midHex: palette.mid,
    highlightBlend: config.highlightBlend,
    highlightOpacity: config.highlightOpacity,
    appearance: config.appearance,
    containerSpacing: config.containerSpacing,
    springDuration: config.springDuration,
    springBounce: config.springBounce,
    // Frozen look (controls removed; hardcoding here also overrides any
    // stored panel values): Regular glass, gray outer stroke @0.13, design
    // shadow at 0.35 alpha / 0.35→14pt radius on the white elements.
    glassVariant: 'regular',
    glassInteractive: config.glassInteractive,
    strokeMode: 'outer',
    strokeColorChoice: 'gray',
    strokeOpacity: 0.13,
    shadowMode: 'design',
    // Historical bridge names — the native side reads absolute 0–1 knobs.
    shadowOpacityScale: 0.35,
    shadowRadiusScale: 0.35,
    frost: config.frostLevel,
    ...frozenLayout,
  };
}
