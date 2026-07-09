import ExpoModulesCore
import SwiftUI

final class GlassToolbarProps: ExpoSwiftUI.ViewProps {
  /// Toolbar configuration 1...8 from the Figma dev spec, 0 = hidden.
  @Field var option: Int = 0
  // The toolbar shares the bar's material/theme/motion config so panel
  // sliders drive both components consistently.
  @Field var config: GlassConfigRecord = GlassConfigRecord()

  var onToolbarPress = EventDispatcher()
}

// Registered as a second (named) view of GlassTabBarModule; the JS side
// mounts it with requireNativeView('GlassTabBar', 'GlassToolbarExpoView').
struct GlassToolbarExpoView: ExpoSwiftUI.View, ExpoSwiftUI.WithHostingView {
  @ObservedObject var props: GlassToolbarProps

  var body: some View {
    GlassToolbarView(
      config: props.config.toConfig(),
      option: props.option,
      onPress: { element, seq in props.onToolbarPress(["element": element, "seq": seq]) }
    )
  }
}
