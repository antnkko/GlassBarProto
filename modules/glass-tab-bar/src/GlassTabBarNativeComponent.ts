import type {HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';
import type {
  DirectEventHandler,
  Double,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

// Codegen spec for the Fabric native component. Mirrors the public
// GlassTabBarNativeProps contract in GlassTabBarView.types.ts — keep the two
// in sync; the public types stay the app-facing API.

type TabPressEvent = Readonly<{
  tab: string;
  seq: Int32;
}>;

type ExpandChangeEvent = Readonly<{
  expanded: boolean;
  seq: Int32;
}>;

export interface NativeProps extends ViewProps {
  expanded: boolean;
  activeTab: string;
  lastSeq: Int32;
  collapsed: boolean;
  config: Readonly<{
    milkOpacity: Double;
    accentHex: string;
    lightHex: string;
    midHex: string;
    highlightBlend: string;
    highlightOpacity: Double;
    appearance: string;
    containerSpacing: Double;
    springDuration: Double;
    springBounce: Double;
    pillWidth: Double;
    pillHeight: Double;
    innerPadding: Double;
    gap: Double;
    hPadding: Double;
    subTabSpacing: Double;
    iconSize: Double;
    plusIconSize: Double;
    strokeMode: string;
    glassVariant: string;
    glassInteractive: boolean;
    shadowMode: string;
    shadowOpacityScale: Double;
    shadowRadiusScale: Double;
    frost: Double;
    strokeColorChoice: string;
    strokeOpacity: Double;
    accentStrokeOpacity: Double;
    accentRingStyle: string;
    accentGlowOpacity: Double;
  }>;
  onTabPress?: DirectEventHandler<TabPressEvent>;
  onSubTabPress?: DirectEventHandler<TabPressEvent>;
  onExpandChange?: DirectEventHandler<ExpandChangeEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'GlassTabBar',
) as HostComponent<NativeProps>;
