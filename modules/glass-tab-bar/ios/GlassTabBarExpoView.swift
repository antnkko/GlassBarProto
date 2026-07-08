import ExpoModulesCore
import SwiftUI

final class GlassConfigRecord: Record {
  @Field var milkOpacity: Double = 0.55

  @Field var accentHex: String = "#F65D00"
  @Field var lightHex: String = "#FFF2ED"
  @Field var midHex: String = "#888A8E"

  @Field var highlightBlend: String = "multiply"
  @Field var highlightOpacity: Double = 1.0

  @Field var appearance: String = "light"

  @Field var containerSpacing: Double = 0

  @Field var springDuration: Double = 0.44
  @Field var springBounce: Double = 0.22

  @Field var pillWidth: Double = 80
  @Field var pillHeight: Double = 62
  @Field var innerPadding: Double = 4
  @Field var gap: Double = 16
  @Field var hPadding: Double = 24
  @Field var subTabSpacing: Double = 0
  @Field var iconSize: Double = 32
  @Field var plusIconSize: Double = 28

  func toConfig() -> GlassTabBarConfig {
    GlassTabBarConfig(
      milkOpacity: milkOpacity,
      accentHex: accentHex,
      lightHex: lightHex,
      midHex: midHex,
      highlightBlend: highlightBlend,
      highlightOpacity: highlightOpacity,
      appearance: appearance,
      containerSpacing: containerSpacing,
      springDuration: springDuration,
      springBounce: springBounce,
      pillWidth: pillWidth,
      pillHeight: pillHeight,
      innerPadding: innerPadding,
      gap: gap,
      hPadding: hPadding,
      subTabSpacing: subTabSpacing,
      iconSize: iconSize,
      plusIconSize: plusIconSize
    )
  }
}

final class GlassTabBarProps: ExpoSwiftUI.ViewProps {
  @Field var expanded: Bool = false
  @Field var activeTab: String = "home"
  @Field var lastSeq: Int = 0
  @Field var collapsed: Bool = false
  @Field var config: GlassConfigRecord = GlassConfigRecord()

  var onTabPress = EventDispatcher()
  var onSubTabPress = EventDispatcher()
  var onExpandChange = EventDispatcher()
}

// WithHostingView makes the view definition wrap this SwiftUI view in a UIKit
// HostingView, so it mounts standalone in the Fabric hierarchy (no @expo/ui <Host>).
struct GlassTabBarExpoView: ExpoSwiftUI.View, ExpoSwiftUI.WithHostingView {
  @ObservedObject var props: GlassTabBarProps

  var body: some View {
    GlassTabBarView(
      config: props.config.toConfig(),
      expanded: props.expanded,
      activeTab: props.activeTab,
      lastSeq: props.lastSeq,
      collapsed: props.collapsed,
      onTabPress: { tab, seq in props.onTabPress(["tab": tab, "seq": seq]) },
      onSubTabPress: { tab, seq in props.onSubTabPress(["tab": tab, "seq": seq]) },
      onExpandChange: { expanded, seq in props.onExpandChange(["expanded": expanded, "seq": seq]) }
    )
  }
}
