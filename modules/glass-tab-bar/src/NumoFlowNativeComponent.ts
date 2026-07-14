import type {HostComponent, ViewProps} from 'react-native';
import type {DirectEventHandler, Int32} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type FlowEvent = Readonly<{
  type: string;
}>;

export interface NativeProps extends ViewProps {
  /** 'braindump' | 'dumped' | 'switch' | 'reset' | 'none' */
  mode: string;
  /** Bump to re-trigger the same mode (RN remounts by key anyway). */
  seq: Int32;
  onFlowEvent?: DirectEventHandler<FlowEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'NumoFlow',
) as HostComponent<NativeProps>;
