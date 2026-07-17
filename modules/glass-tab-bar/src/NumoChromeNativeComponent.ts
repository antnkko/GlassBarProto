import type {HostComponent, ViewProps} from 'react-native';
import type {
  DirectEventHandler,
  Double,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export type ChromePressEvent = {
  /** 'close' | 'clear' | 'confirm'. */
  element: string;
};

/**
 * Stage 50 — the redesigned screen's top chrome as a native Fabric leaf:
 * the ✕ + publicity/tags pill (closed) ⇄ Clear + ✓ (picker open) clusters and
 * the centered "When" title, hosted SwiftUI (the same GlassButton material the
 * toolbar uses). The cluster swap runs internally on the native springs when
 * `pickerOpen` flips (blur+opacity, MorphChoreo.placeholderSwap) — exactly the
 * RedesignedScreen header. The RN flow animates only this leaf's CONTAINER
 * (entrance drop / close crop counter-translate), keeping glass native while
 * the choreography lives in Reanimated.
 */
export interface NativeProps extends ViewProps {
  /** Swaps ✕+publicity ⇄ Clear+✓ (+ shows the picker title) natively. */
  pickerOpen?: WithDefault<boolean, false>;
  /** Centered header title while a picker is open — "When" | "Routine".
   *  RN latches it on open (mirrors the native pickerTitle latch). */
  pickerTitle?: WithDefault<string, 'When'>;
  /** Auto-detected tag shown in the publicity pill ('' = none). */
  tag?: WithDefault<string, ''>;
  /** Glass shadow knobs (GlassTabBarConfig.frozen), same as NumoFlow. */
  shadowOpacity: Double;
  shadowRadius: Double;
  onChromePress?: DirectEventHandler<ChromePressEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'NumoChrome',
) as HostComponent<NativeProps>;
