import type {ViewProps} from 'react-native';

export type BarAppearance = 'light' | 'dark';
export type HighlightBlend = 'multiply' | 'normal';

export type RootTab = 'home' | 'plus' | 'squad';
export type SubTab = 'squad' | 'chat' | 'play';
export type ActiveTab = 'home' | SubTab;

/** Mirrors GlassConfigRecord in GlassTabBarExpoView.swift field-for-field. */
export interface GlassConfig {
  /** White layer between the glass and the content. 0 = raw glass. */
  milkOpacity: number;

  accentHex: string;
  lightHex: string;
  midHex: string;

  /** Figma: mix-blend-multiply — the highlight lets glass/backdrop light through. */
  highlightBlend: HighlightBlend;
  highlightOpacity: number;

  appearance: BarAppearance;

  containerSpacing: number;

  springDuration: number;
  springBounce: number;

  pillWidth: number;
  pillHeight: number;
  innerPadding: number;
  gap: number;
  hPadding: number;
  subTabSpacing: number;
  iconSize: number;
  plusIconSize: number;
}

export interface TabPressEvent {
  tab: RootTab | 'plus';
  seq: number;
}

export interface SubTabPressEvent {
  tab: SubTab;
  seq: number;
}

export interface ExpandChangeEvent {
  expanded: boolean;
  seq: number;
}

export interface GlassTabBarNativeProps extends ViewProps {
  expanded: boolean;
  activeTab: ActiveTab;
  /** Echo of the last seq RN has processed — the native side uses it to ignore stale controlled values. */
  lastSeq: number;
  /** Instagram-style minimize: true while the content scrolls down. */
  collapsed: boolean;
  config: GlassConfig;
  onTabPress?: (event: {nativeEvent: TabPressEvent}) => void;
  onSubTabPress?: (event: {nativeEvent: SubTabPressEvent}) => void;
  onExpandChange?: (event: {nativeEvent: ExpandChangeEvent}) => void;
}
