import type {ViewProps} from 'react-native';

import type {GlassConfig} from './GlassTabBarView.types';

/** Toolbar configuration from the Figma dev spec (node 278:2416). 0 = hidden. */
export type ToolbarOption = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;

export type ToolbarElement =
  | 'back'
  | 'settings'
  | 'close'
  | 'avatar'
  | 'translate'
  | 'aa'
  | 'more'
  | 'cta';

export interface ToolbarPressEvent {
  element: ToolbarElement;
  seq: number;
}

export interface GlassToolbarNativeProps extends ViewProps {
  option: ToolbarOption;
  /** Shares the bar's material/theme/motion config so both stay consistent. */
  config: GlassConfig;
  onToolbarPress?: (event: {nativeEvent: ToolbarPressEvent}) => void;
}
