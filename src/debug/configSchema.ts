import type {BarAppearance, GlassConfig, HighlightBlend, ToolbarOption} from '../../modules/glass-tab-bar';

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

  /** Height of the top progressive blur strip below the safe area. */
  toolbarEdgeHeight: number;
  /** Height of the bottom progressive blur strip above the home indicator. */
  edgeBottomHeight: number;
  /** Blur strength of the edge strips. */
  edgeMaterial: EdgeMaterial;
  /** 0..0.8 — portion of the strip that stays fully blurred before fading. */
  edgeFadeStart: number;
  /** Falloff gamma: 1 = linear fade, higher = steeper drop. */
  edgeCurve: number;
  /** 0..1 global multiplier on the strips. */
  edgeIntensity: number;
}

export type EdgeMaterial = 'ultraThin' | 'thin' | 'regular' | 'thick';

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
  toolbarEdgeHeight: 356,
  edgeBottomHeight: 96,
  edgeMaterial: 'thick',
  edgeFadeStart: 0.35,
  edgeCurve: 1.4,
  edgeIntensity: 1,
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
    ...frozenLayout,
  };
}
