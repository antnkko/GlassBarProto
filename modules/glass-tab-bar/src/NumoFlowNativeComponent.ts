import type {HostComponent, ViewProps} from 'react-native';
import type {
  DirectEventHandler,
  Double,
  Int32,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/**
 * type values:
 * - 'closed'        — flow fully closed (existing)
 * - 'closing'       — close started; the RN bottom-bar cluster fades out
 * - 'barEnterSlide' — slide-up entry reached the bottom-bar beat (+40pt rise)
 * - 'barEnterMorph' — morph entry reached the bottom-bar beat (+280pt rise)
 * - 'clearWhen'     — native Clear pill tapped (RN resets day/time + closes)
 * - 'confirmWhen'   — native ✓ tapped (RN closes the picker)
 * - 'backdropTap'   — input-area tap-catcher tapped while the picker is open
 */
type FlowEvent = Readonly<{
  type: string;
}>;

export interface NativeProps extends ViewProps {
  /** 'braindump' | 'dumped' | 'switch' | 'reset' | 'none' */
  mode: string;
  /** Bump to re-trigger the same mode (RN remounts by key anyway). */
  seq: Int32;
  /** Braindump chrome glass shadow (mirrors the dev panel), 0–1. */
  shadowOpacity: Double;
  shadowRadius: Double;
  /**
   * RN owns the bottom-bar cluster (chip/picker shell + voice button): the
   * native screen skips building its own and emits picker events instead.
   */
  rnBottomBar?: WithDefault<boolean, false>;
  /**
   * Mirrors the RN-owned When-picker state into the native screen — drives
   * the header swap (✕/publicity ⇄ Clear/✓), the input backdrop blur/dim and
   * the tap-to-close catcher. Only meaningful with `rnBottomBar`.
   */
  whenPickerOpen?: WithDefault<boolean, false>;
  onFlowEvent?: DirectEventHandler<FlowEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'NumoFlow',
) as HostComponent<NativeProps>;
