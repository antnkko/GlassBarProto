import type {HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';
import type {
  DirectEventHandler,
  Double,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

// Codegen spec for the glass toolbar (Figma dev-spec configurations 1-8).
// The config object is intentionally identical to the tab bar's — both
// components share one material/theme/motion config on the JS side.

type ToolbarPressEvent = Readonly<{
  element: string;
  seq: Int32;
}>;

export interface NativeProps extends ViewProps {
  /** Toolbar configuration 1...8, 0 = hidden. */
  option: Int32;
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
  }>;
  onToolbarPress?: DirectEventHandler<ToolbarPressEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'GlassToolbar',
) as HostComponent<NativeProps>;
